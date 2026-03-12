import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/news/domain/feed_news.dart';

/// Service d’envoi des événements analytics au backend.
/// Permet de mesurer : articles lus, provenance, médias les plus lus, partages.
/// À brancher sur les vrais endpoints (voir docs/backend-api-analytics.md).
class AnalyticsService {
  // TODO: injecter Dio + baseUrl + token utilisateur

  /// Enregistre une lecture d’article (à appeler à l’ouverture du détail).
  Future<void> trackArticleView(FeedNews article, {String? country, String? region}) async {
    // POST /api/v1/events/article-view
    // { articleId, sourceId, sourceName, publishedAt, userId?, anonymousId?, country?, region?, at }
    await Future<void>.value();
  }

  /// Enregistre un partage (lien, PDF, WhatsApp, etc.).
  Future<void> trackArticleShare(FeedNews article, {required String shareMethod}) async {
    // POST /api/v1/events/article-share
    // { articleId, sourceId, shareMethod, userId?, anonymousId?, at }
    await Future<void>.value();
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
