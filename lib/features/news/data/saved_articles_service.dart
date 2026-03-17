import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';
import '../domain/feed_news.dart';

class SavedArticlesService {
  final Dio _dio;
  static const String _baseUrl = AppConfig.apiBaseUrl;

  SavedArticlesService({Dio? dio, String? token})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: token != null ? {'Authorization': 'Bearer $token'} : {},
            ));

  Future<List<FeedNews>> fetchSavedArticles() async {
    try {
      final res = await _dio.get('/api/v1/saved-articles');
      final List<dynamic> data = res.data['savedArticles'] ?? [];
      return (data as List).map((json) {
        // Map backend schema to FeedNews domain
        return FeedNews(
          id: json['articleId'] as String? ?? '',
          sourceId: json['sourceId'] as String? ?? '',
          sourceName: '', // Backend doesn't store source name, UI will map it via provider
          title: json['title'] as String? ?? '',
          imageUrl: json['image_url'] as String?,
          publishedAt: json['published_at'] != null 
              ? DateTime.tryParse(json['published_at'] as String) ?? DateTime.now() 
              : DateTime.now(),
          originalUrl: '', // Not stored in saved_articles table
          excerpt: '',
          content: '',
          feedType: 'rss',
        );
      }).toList();
    } catch (e) {
      print('Error fetching saved articles: $e');
      return [];
    }
  }

  Future<bool> toggleSavedArticle(FeedNews article) async {
    try {
      final res = await _dio.post('/api/v1/saved-articles', data: {
        'articleId': article.id,
        'sourceId': article.sourceId,
        'title': article.title,
        'imageUrl': article.imageUrl,
        'publishedAt': article.publishedAt.toIso8601String(),
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Error toggling saved article: $e');
      return false;
    }
  }
}
