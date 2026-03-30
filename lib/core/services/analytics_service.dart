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
      final payload = <String, dynamic>{
        'articleId': article.id,
        'type': 'view',
        'source': article.sourceName,
        'title': article.title,
        'category': article.category,
        'deviceType': defaultTargetPlatform.name.toLowerCase(),
      };

      final deviceId = LocalStorage.getAnonymousId();
      if (deviceId != null) {
        payload['deviceId'] = deviceId;
      }

      await _dio.post('/api/v1/events', data: payload);
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] Error tracking view: $e');
    }
  }

  /// Enregistre un signal de présence (pulse) pour mesurer la durée.
  Future<void> trackArticlePulse(FeedNews article, int durationSeconds) async {
    try {
      final payload = <String, dynamic>{
        'articleId': article.id,
        'type': 'pulse',
        'duration': durationSeconds,
        'source': article.sourceName,
        'title': article.title,
      };

      final deviceId = LocalStorage.getAnonymousId();
      if (deviceId != null) {
        payload['deviceId'] = deviceId;
      }

      await _dio.post('/api/v1/events', data: payload);
      if (kDebugMode) {
        debugPrint('[Analytics] pulse tracked → ${article.id} (${durationSeconds}s)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] Error tracking pulse: $e');
    }
  }

  /// Enregistre un partage d'article.
  Future<void> trackArticleShare(FeedNews article,
      {required String shareMethod}) async {
    try {
      final payload = <String, dynamic>{
        'articleId': article.id,
        'type': 'share',
        'source': article.sourceName,
        'title': article.title,
        'category': article.category,
      };

      await _dio.post('/api/v1/events', data: payload);
      if (kDebugMode) {
        debugPrint('[Analytics] share tracked → ${article.id}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] Error tracking share: $e');
    }
  }
}

final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => AnalyticsService());
