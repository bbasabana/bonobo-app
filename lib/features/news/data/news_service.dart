import 'package:dio/dio.dart';
import 'package:webfeed_plus/webfeed_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/media_sources.dart';
import '../../../core/utils/html_parser.dart';
import '../domain/feed_news.dart';
import '../domain/media_source.dart';

class NewsService {
  final Dio _dio;

  NewsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: AppConstants.feedFetchTimeout,
              receiveTimeout: AppConstants.feedFetchTimeout,
              followRedirects: true,
              maxRedirects: 3,
              headers: {'Accept': 'application/json, application/rss+xml, text/xml'},
            ));

  Future<List<FeedNews>> fetchAllFeeds() async {
    final futures = MediaSources.all.map((source) =>
        _fetchSingleFeed(source)
            .timeout(
              AppConstants.perSourceFetchTimeout,
              onTimeout: () => <FeedNews>[],
            )
            .catchError((_) => <FeedNews>[]));
    final results = await Future.wait(futures);
    final all = results.expand((list) => list).toList();

    final seen = <String>{};
    final deduped = all.where((a) => seen.add(a.originalUrl)).toList();
    deduped.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return deduped;
  }

  Future<List<FeedNews>> fetchFeedForSource(String sourceId) async {
    final source = MediaSources.findById(sourceId);
    if (source == null) return [];
    return _fetchSingleFeed(source);
  }

  /// Fetch dédié à la page média — limite personnalisée (ex. 45 articles).
  /// Contourne la limite globale `maxArticlesPerFeed` de la home.
  Future<List<FeedNews>> fetchFeedForSourceWithLimit(
      String sourceId, int limit) async {
    final source = MediaSources.findById(sourceId);
    if (source == null) return [];
    if (source.feedType == FeedType.rss) {
      return _fetchRssWithLimit(source, limit);
    }
    return _fetchWordPressWithLimit(source, limit);
  }

  String _buildWordPressUrlWithLimit(String baseUrl, int limit) {
    final uri = Uri.parse(baseUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['per_page'] = limit.toString();
    params['_fields'] =
        'id,date,title,excerpt,content,link,jetpack_featured_media_url,featured_media_source';
    return uri.replace(queryParameters: params).toString();
  }

  Future<List<FeedNews>> _fetchWordPressWithLimit(
      MediaSource source, int limit) async {
    try {
      final url = _buildWordPressUrlWithLimit(source.feedUrl, limit);
      final response = await _dio.get<List<dynamic>>(url);
      final posts = response.data ?? [];
      return posts
          .map((post) => _parseWordPressPost(post as Map<String, dynamic>, source))
          .whereType<FeedNews>()
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<FeedNews>> _fetchRssWithLimit(MediaSource source, int limit) async {
    try {
      final response = await _dio.get<String>(source.feedUrl);
      final body = response.data ?? '';
      final feed = RssFeed.parse(body);
      final items = (feed.items ?? []).take(limit);
      return items
          .map((item) => _parseRssItem(item, source))
          .whereType<FeedNews>()
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<FeedNews>> _fetchSingleFeed(MediaSource source) async {
    if (source.feedType == FeedType.rss) {
      return _fetchRss(source);
    }
    return _fetchWordPress(source);
  }

  /// Construit l'URL WordPress optimisée :
  /// - per_page limité
  /// - _fields pour n'envoyer que les champs nécessaires (évite yoast_head, _links, meta…)
  String _buildWordPressUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['per_page'] = AppConstants.maxArticlesPerFeed.toString();
    params['_fields'] =
        'id,date,title,excerpt,content,link,jetpack_featured_media_url,featured_media_source';
    return uri.replace(queryParameters: params).toString();
  }

  Future<List<FeedNews>> _fetchWordPress(MediaSource source) async {
    try {
      final url = _buildWordPressUrl(source.feedUrl);
      final response = await _dio.get<List<dynamic>>(url);
      final posts = response.data ?? [];
      return posts
          .map((post) => _parseWordPressPost(post as Map<String, dynamic>, source))
          .whereType<FeedNews>()
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  FeedNews? _parseWordPressPost(Map<String, dynamic> post, MediaSource source) {
    try {
      final id = post['id']?.toString() ?? '';
      final rawTitle =
          (post['title'] as Map<String, dynamic>?)?['rendered']?.toString() ?? '';
      final title = HtmlUtils.decodeHtmlEntities(HtmlUtils.stripHtml(rawTitle));
      if (title.isEmpty) return null;

      final excerptRendered =
          (post['excerpt'] as Map<String, dynamic>?)?['rendered']?.toString() ?? '';
      final contentRendered =
          (post['content'] as Map<String, dynamic>?)?['rendered']?.toString() ?? '';

      // Priorité à l'excerpt pour l'aperçu — évite de parser le contenu complet
      final excerpt = excerptRendered.isNotEmpty
          ? HtmlUtils.cleanExcerpt(excerptRendered)
          : HtmlUtils.cleanExcerpt(contentRendered);

      // Contenu complet pour la vue détail (HTML brut, strippé à la lecture)
      final content = HtmlUtils.stripHtml(contentRendered);

      String? imageUrl =
          (post['featured_media_source'] as Map<String, dynamic>?)?['source_url']
              as String?;
      imageUrl ??= post['jetpack_featured_media_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = HtmlUtils.extractFirstImageUrl(contentRendered);
      }

      final dateStr = post['date'] as String? ?? '';
      final publishedAt = DateTime.tryParse(dateStr) ?? DateTime.now();
      final link = post['link'] as String? ?? '';
      final category =
          source.categories.isNotEmpty ? source.categories.join(', ') : null;

      return FeedNews(
        id: '${source.id}_$id',
        title: title,
        imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
        excerpt: excerpt,
        content: content,
        publishedAt: publishedAt,
        sourceName: source.name,
        sourceId: source.id,
        sourceLogo: source.logoUrl.isNotEmpty ? source.logoUrl : null,
        originalUrl: link,
        category: category,
        feedType: 'wordpress',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<FeedNews>> _fetchRss(MediaSource source) async {
    try {
      final response = await _dio.get<String>(source.feedUrl);
      final body = response.data ?? '';
      final feed = RssFeed.parse(body);
      final items = (feed.items ?? []).take(AppConstants.maxArticlesPerFeed);
      return items
          .map((item) => _parseRssItem(item, source))
          .whereType<FeedNews>()
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  FeedNews? _parseRssItem(RssItem item, MediaSource source) {
    try {
      final rawRssTitle = item.title?.trim() ?? '';
      final title = HtmlUtils.decodeHtmlEntities(rawRssTitle);
      if (title.isEmpty) return null;

      final contentRaw = item.content?.value ?? item.description ?? '';
      final content = HtmlUtils.stripHtml(contentRaw);
      final excerpt = HtmlUtils.cleanExcerpt(contentRaw);

      String? imageUrl = item.enclosure?.url;
      imageUrl ??= HtmlUtils.extractFirstImageUrl(contentRaw);

      final publishedAt = item.pubDate ?? DateTime.now();
      final link = item.link ?? '';
      final id = (item.guid ?? link).hashCode.toString();

      return FeedNews(
        id: '${source.id}_$id',
        title: title,
        imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
        excerpt: excerpt,
        content: content,
        publishedAt: publishedAt,
        sourceName: source.name,
        sourceId: source.id,
        sourceLogo: source.logoUrl.isNotEmpty ? source.logoUrl : null,
        originalUrl: link,
        category: source.categories.isNotEmpty ? source.categories.join(', ') : null,
        feedType: 'rss',
      );
    } catch (_) {
      return null;
    }
  }
}
