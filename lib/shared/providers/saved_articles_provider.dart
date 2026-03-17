import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/news/domain/feed_news.dart';
import '../local_storage.dart';

import '../../features/news/data/saved_articles_service.dart';
import 'auth_provider.dart';

/// Provider qui gère la liste des articles sauvegardés (favoris/bibliothèque).
/// Requiert une connexion authentifiée (vérification côté UI).
/// État = liste des IDs sauvegardés (persistés via Hive).
class SavedArticlesNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  
  SavedArticlesNotifier(this._ref) : super(LocalStorage.getSavedArticleIds()) {
    // Sync with backend on startup if authenticated
    _syncWithBackend();
  }

  Future<void> _syncWithBackend() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    final service = SavedArticlesService(token: auth.token);
    final remoteArticles = await service.fetchSavedArticles();
    
    // Add remote articles to local storage and update state
    for (var art in remoteArticles) {
      if (!state.contains(art.id)) {
        await LocalStorage.addSavedArticle(art);
      }
    }
    
    state = LocalStorage.getSavedArticleIds();
  }

  bool isSaved(String articleId) => state.contains(articleId);

  /// Ajoute ou retire un article. Retourne [true] si ajouté, [false] si retiré.
  Future<bool> toggle(FeedNews article) async {
    final auth = _ref.read(authProvider);
    final isLocalOnly = !auth.isAuthenticated;

    if (state.contains(article.id)) {
      await LocalStorage.removeSavedArticle(article.id);
      if (!isLocalOnly) {
        final service = SavedArticlesService(token: auth.token);
        await service.toggleSavedArticle(article);
      }
      state = state.where((id) => id != article.id).toList();
      return false;
    } else {
      await LocalStorage.addSavedArticle(article);
      if (!isLocalOnly) {
        final service = SavedArticlesService(token: auth.token);
        await service.toggleSavedArticle(article);
      }
      state = [article.id, ...state];
      return true;
    }
  }

  /// Retourne les articles sauvegardés complets (pour la page bibliothèque).
  List<FeedNews> get savedArticles => LocalStorage.getSavedArticles();
}

final savedArticlesProvider =
    StateNotifierProvider<SavedArticlesNotifier, List<String>>(
  (ref) => SavedArticlesNotifier(ref),
);
