import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_config.dart';

import '../../features/news/domain/feed_news.dart';
import '../../shared/local_storage.dart';

/// Service d'envoi des événements analytics au backend.
/// Documenation : docs/backend-api-analytics.md
class AnalyticsService {
  late final Dio _dio;
  static const String _baseUrl = AppConfig.apiBaseUrl;

  AnalyticsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout:
            const Duration(seconds: AppConfig.analyticsTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: AppConfig.analyticsTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Enregistre une lecture d'article.
  /// Appelé à l'ouverture de ArticleDetailScreen.
  Future<void> trackArticleView(FeedNews article) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final payload = <String, dynamic>{
        'articleId': article.id,
        'sourceId': article.sourceId,
        'sourceName': article.sourceName,
        'publishedAt': article.publishedAt.toUtc().toIso8601String(),
        'at': now,
        'device': defaultTargetPlatform.name,
      };

      final userId = LocalStorage.getUserId();
      if (userId != null) {
        payload['userId'] = userId;
      } else {
        payload['anonymousId'] = LocalStorage.getAnonymousId();
      }

      await _dio.post('/api/v1/events/article-view', data: payload);
      if (kDebugMode) {
        debugPrint('[Analytics] article-view → ${article.id}');
      }
    } catch (e) {
      // Les erreurs analytics sont silencieuses — ne jamais bloquer l'UX.
      if (kDebugMode) debugPrint('[Analytics] Error article-view: $e');
    }
  }

  /// Enregistre un partage d'article.
  /// [shareMethod] : "link" | "pdf" | "whatsapp" | "twitter" | "copy"
  Future<void> trackArticleShare(FeedNews article,
      {required String shareMethod}) async {
    try {
      final payload = <String, dynamic>{
        'articleId': article.id,
        'sourceId': article.sourceId,
        'shareMethod': shareMethod,
        'at': DateTime.now().toUtc().toIso8601String(),
      };

      final userId = LocalStorage.getUserId();
      if (userId != null) {
        payload['userId'] = userId;
      } else {
        payload['anonymousId'] = LocalStorage.getAnonymousId();
      }

      await _dio.post('/api/v1/events/article-share', data: payload);
      if (kDebugMode) {
        debugPrint('[Analytics] article-share → ${article.id} via $shareMethod');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] Error article-share: $e');
    }
  }
}

final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => AnalyticsService());
