import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/news/domain/feed_news.dart';
import '../local_storage.dart';

/// Provider qui gère la liste des articles sauvegardés (favoris/bibliothèque).
/// Requiert une connexion authentifiée (vérification côté UI).
/// État = liste des IDs sauvegardés (persistés via Hive).
class SavedArticlesNotifier extends StateNotifier<List<String>> {
  SavedArticlesNotifier() : super(LocalStorage.getSavedArticleIds());

  bool isSaved(String articleId) => state.contains(articleId);

  /// Ajoute ou retire un article. Retourne [true] si ajouté, [false] si retiré.
  Future<bool> toggle(FeedNews article) async {
    if (state.contains(article.id)) {
      await LocalStorage.removeSavedArticle(article.id);
      state = state.where((id) => id != article.id).toList();
      return false;
    } else {
      await LocalStorage.addSavedArticle(article);
      state = [article.id, ...state];
      return true;
    }
  }

  /// Retourne les articles sauvegardés complets (pour la page bibliothèque).
  List<FeedNews> get savedArticles => LocalStorage.getSavedArticles();
}

final savedArticlesProvider =
    StateNotifierProvider<SavedArticlesNotifier, List<String>>(
  (ref) => SavedArticlesNotifier(),
);
