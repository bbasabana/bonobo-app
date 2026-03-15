import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/backend_news_service.dart';
import '../data/news_service.dart';
import '../domain/feed_news.dart';
import '../domain/media_source.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/local_storage.dart';
import '../../../core/constants/media_sources.dart';

final newsServiceProvider = Provider<NewsService>((ref) => BackendNewsService());

const _fetchTimeout = Duration(seconds: 20);

/// Indique si un fetch réseau est en cours (barre de progression fine).
final newsRefreshingProvider = StateProvider<bool>((ref) => false);

/// Dernière erreur de chargement (null = pas d'erreur).
final newsLastErrorProvider = StateProvider<String?>((ref) => null);

/// Provider dynamic des sources (depuis le backend).
final dynamicMediaSourcesProvider = FutureProvider<List<MediaSource>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  final cached = LocalStorage.getMediaSources(); // Should implement this if possible, or just fetch for now
  
  if (cached.isNotEmpty) {
    _refreshSources(ref, service);
    return cached;
  }
  
  return await service.fetchMediaSources();
});

void _refreshSources(Ref ref, NewsService service) async {
    try {
      final fresh = await service.fetchMediaSources();
      if (fresh.isNotEmpty) {
        await LocalStorage.saveMediaSources(fresh);
        ref.invalidate(dynamicMediaSourcesProvider);
      }
    } catch (_) {}
}

/// Provider principal — CACHE EN PREMIER.
///
/// - Si cache disponible (même périmé) : retourne immédiatement les données
///   et lance un refresh réseau silencieux en arrière-plan.
/// - Si aucun cache (première installation) : fetch réseau complet.
final newsListProvider = FutureProvider<List<FeedNews>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  final cached = LocalStorage.getArticles();

  if (cached.isNotEmpty) {
    ref.read(newsLastErrorProvider.notifier).state = null;
    if (LocalStorage.isNewsExpired()) {
      // Cache expiré → afficher les données existantes ET rafraîchir en fond
      _backgroundRefresh(ref, service);
    }
    return cached; // Retour immédiat, pas d'attente réseau
  }

  // Premier lancement : pas de cache → fetch réseau complet
  return _fetchFromNetwork(ref, service);
});

/// Lance un refresh réseau sans bloquer l'UI.
void _backgroundRefresh(Ref ref, NewsService service) {
  Future.microtask(() async {
    if (ref.read(newsRefreshingProvider)) return; // Déjà en cours
    ref.read(newsRefreshingProvider.notifier).state = true;
    try {
      final previousCount = LocalStorage.getArticles().length;
      final fresh = await service.fetchAllFeeds().timeout(
        _fetchTimeout,
        onTimeout: () => <FeedNews>[],
      );
      if (fresh.isNotEmpty) {
        await LocalStorage.saveArticles(fresh);
        // Invalide le provider → re-build instantané depuis le cache frais
        ref.invalidate(newsListProvider);
        // Notification sonore si de nouveaux articles sont arrivés
        final newCount = fresh.length - previousCount;
        if (newCount > 0) {
          _triggerNewArticlesNotification(newCount);
        }
      }
    } catch (_) {
      // Silencieux : l'utilisateur voit le cache existant
    } finally {
      ref.read(newsRefreshingProvider.notifier).state = false;
    }
  });
}

void _triggerNewArticlesNotification(int count) {
  Future.microtask(() async {
    try {
      final notif = NotificationService();
      await notif.playNewArticlesSound();
      await notif.showNewArticlesNotification(count: count);
    } catch (_) {}
  });
}

/// Fetch réseau complet (première installation, aucun cache).
Future<List<FeedNews>> _fetchFromNetwork(Ref ref, NewsService service) async {
  ref.read(newsRefreshingProvider.notifier).state = true;
  try {
    final fresh = await service.fetchAllFeeds().timeout(
      _fetchTimeout,
      onTimeout: () => throw TimeoutException('Délai de chargement dépassé'),
    );
    ref.read(newsRefreshingProvider.notifier).state = false;
    ref.read(newsLastErrorProvider.notifier).state = null;
    if (fresh.isNotEmpty) {
      await LocalStorage.saveArticles(fresh);
      return fresh;
    }
    return [];
  } catch (e) {
    ref.read(newsRefreshingProvider.notifier).state = false;
    final errMsg = e is TimeoutException
        ? 'Chargement lent – vérifiez votre connexion'
        : 'Connexion instable ou indisponible';
    ref.read(newsLastErrorProvider.notifier).state = errMsg;
    return [];
  }
}

final newsForSourceProvider =
    FutureProvider.family<List<FeedNews>, String>((ref, sourceId) async {
  final allNews = await ref.watch(newsListProvider.future);
  return allNews.where((a) => a.sourceId == sourceId).toList();
});

/// Provider dédié à la page détail d'un média.
/// CACHE EN PREMIER → réponse immédiate, pas de page blanche.
/// Si aucun cache (première visite) → fetch réseau (50 articles max).
/// Limite haute : 150 articles par média.
/// Le service récupère autant que disponible jusqu'à ce plafond.
const _mediaDetailLimit = 150;

final mediaDetailArticlesProvider =
    FutureProvider.family<List<FeedNews>, String>((ref, sourceId) async {
  // 1. Cache d'abord : retour immédiat sans aucune attente réseau
  final allCached = LocalStorage.getArticles();
  final cached = allCached.where((a) => a.sourceId == sourceId).toList();
  if (cached.isNotEmpty) return cached;

  // 2. Aucun cache (première visite de ce média) → fetch réseau
  // Timeout plus long (25s) pour les sources lentes (ex. Grands Lacs, Scoop RDC).
  final service = ref.watch(newsServiceProvider);
  try {
    return await service
        .fetchFeedForSourceWithLimit(sourceId, _mediaDetailLimit)
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () => <FeedNews>[],
        );
  } catch (_) {
    return [];
  }
});

final newsForCategoryProvider =
    FutureProvider.family<List<FeedNews>, String>((ref, category) async {
  final allNews = await ref.watch(newsListProvider.future);
  final catLower = category.toLowerCase().trim();
  return allNews.where((a) {
    final c = a.category?.toLowerCase() ?? '';
    if (c.isEmpty) return false;
    return c.split(',').any((s) => s.trim().toLowerCase() == catLower);
  }).toList();
});

final heroArticlesProvider = FutureProvider<List<FeedNews>>((ref) async {
  final allNews = await ref.watch(newsListProvider.future);
  return allNews.take(10).toList();
});

/// Refresh explicite (pull-to-refresh) : marque le cache expiré
/// → le provider retourne le cache immédiatement + lance _backgroundRefresh.
final refreshNewsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await LocalStorage.markNewsExpired();
    ref.invalidate(newsListProvider);
  };
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchSourceIdProvider = StateProvider<String?>((ref) => null);
final searchCategoryProvider = StateProvider<String?>((ref) => null);
final searchDateRangeProvider = StateProvider<String?>((ref) => null);

/// Résultats de recherche (full-text titre + excerpt, avec filtres).
final searchResultsProvider = Provider<List<FeedNews>>((ref) {
  final all = ref.watch(newsListProvider).valueOrNull ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final sourceId = ref.watch(searchSourceIdProvider);
  final category = ref.watch(searchCategoryProvider);
  final dateRange = ref.watch(searchDateRangeProvider);

  var list = all;

  if (sourceId != null && sourceId.isNotEmpty) {
    list = list.where((a) => a.sourceId == sourceId).toList();
  }
  if (category != null && category.isNotEmpty) {
    list = list.where((a) {
      final c = a.category?.toLowerCase() ?? '';
      return c.contains(category.toLowerCase()) ||
          c.split(', ').any((s) => s.trim().toLowerCase() == category.toLowerCase());
    }).toList();
  }
  if (dateRange != null) {
    final now = DateTime.now();
    DateTime cutoff;
    switch (dateRange) {
      case '24h':
        cutoff = now.subtract(const Duration(hours: 24));
        break;
      case '7j':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '30j':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      default:
        cutoff = DateTime(2000);
    }
    list = list.where((a) => a.publishedAt.isAfter(cutoff)).toList();
  }

  if (query.isEmpty) return list;

  final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return list.where((a) {
    final title = a.title.toLowerCase();
    final excerpt = a.excerpt.toLowerCase();
    return words.every((w) => title.contains(w) || excerpt.contains(w));
  }).toList();
});

final mediaSourcesMapProvider = Provider<Map<String, MediaSource>>((ref) {
  final asyncSources = ref.watch(dynamicMediaSourcesProvider);
  final sources = asyncSources.valueOrNull ?? [];
  return {for (var s in sources) s.id: s};
});
