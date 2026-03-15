import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';
import '../domain/feed_news.dart';
import '../domain/media_source.dart';
import 'news_service.dart';

class BackendNewsService implements NewsService {
  final Dio _dio;

  BackendNewsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  @override
  Future<List<FeedNews>> fetchAllFeeds() async {
    try {
      final res = await _dio.get('/api/v1/news');
      final List<dynamic> articles = res.data['articles'] ?? [];
      return articles.map((json) => _parseArticle(json)).toList();
    } catch (e) {
      print('Error fetching backend feeds: $e');
      return [];
    }
  }

  @override
  Future<List<MediaSource>> fetchMediaSources() async {
    try {
      final res = await _dio.get('/api/v1/media-sources');
      final List<dynamic> sources = res.data['sources'] ?? [];
      return sources.map((json) => MediaSource.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching media sources: $e');
      return [];
    }
  }

  @override
  Future<List<FeedNews>> fetchFeedForSource(String sourceId) async {
    try {
      final res = await _dio.get('/api/v1/news', queryParameters: {'sourceId': sourceId});
      final List<dynamic> articles = res.data['articles'] ?? [];
      return articles.map((json) => _parseArticle(json)).toList();
    } catch (e) {
      print('Error fetching backend source feed: $e');
      return [];
    }
  }

  Future<List<FeedNews>> fetchFeedForSourceWithLimit(String sourceId, int limit) async {
    // Current backend doesn't support limit param yet, but we can slice for now
    final articles = await fetchFeedForSource(sourceId);
    if (articles.length > limit) {
      return articles.take(limit).toList();
    }
    return articles;
  }

  FeedNews _parseArticle(Map<String, dynamic> json) {
    return FeedNews(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      excerpt: json['excerpt'],
      content: json['content'],
      publishedAt: DateTime.tryParse(json['publishedAt']) ?? DateTime.now(),
      sourceName: json['sourceName'],
      sourceId: json['sourceId'],
      sourceLogo: null, // Backend could be enhanced to provide this
      originalUrl: json['url'],
      category: (json['categories'] as List<dynamic>?)?.join(', '),
      feedType: json['feedType'],
    );
  }
}
