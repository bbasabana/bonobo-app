import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_storage.dart';
import '../models/local_reaction.dart';

// ─── État réactions d'un article ─────────────────────────────────────────────
class ReactionsState {
  final ArticleReaction reaction;
  final List<LocalComment> comments;

  const ReactionsState({required this.reaction, required this.comments});

  ReactionsState copyWith({ArticleReaction? reaction, List<LocalComment>? comments}) =>
      ReactionsState(
        reaction: reaction ?? this.reaction,
        comments: comments ?? this.comments,
      );
}

class ReactionsNotifier extends StateNotifier<ReactionsState> {
  final String articleId;

  ReactionsNotifier(this.articleId)
      : super(ReactionsState(
          reaction: LocalStorage.getReaction(articleId),
          comments: LocalStorage.getComments(articleId),
        ));

  Future<void> toggleLike() async {
    final r = state.reaction;
    final newReaction = ArticleReaction(
      articleId: r.articleId,
      isLiked: !r.isLiked,
      isDisliked: r.isLiked ? r.isDisliked : false,
      totalLikes: r.isLiked ? (r.totalLikes - 1).clamp(0, 999999) : r.totalLikes + 1,
    );
    await LocalStorage.saveReaction(newReaction);
    state = state.copyWith(reaction: newReaction);
  }

  Future<void> toggleDislike() async {
    final r = state.reaction;
    final newReaction = ArticleReaction(
      articleId: r.articleId,
      isLiked: r.isDisliked ? r.isLiked : false,
      isDisliked: !r.isDisliked,
      totalLikes: r.isLiked && !r.isDisliked ? (r.totalLikes - 1).clamp(0, 999999) : r.totalLikes,
    );
    await LocalStorage.saveReaction(newReaction);
    state = state.copyWith(reaction: newReaction);
  }

  Future<void> addComment(String authorName, String text) async {
    if (text.trim().isEmpty) return;
    final comment = LocalComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      articleId: articleId,
      authorName: authorName,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    final updated = [comment, ...state.comments];
    await LocalStorage.saveComments(articleId, updated);
    state = state.copyWith(comments: updated);
  }

  Future<void> likeComment(String commentId) async {
    final updated = state.comments.map((c) {
      if (c.id != commentId) return c;
      c.isLikedByMe = !c.isLikedByMe;
      c.likes = c.isLikedByMe ? c.likes + 1 : (c.likes - 1).clamp(0, 999999);
      return c;
    }).toList();
    await LocalStorage.saveComments(articleId, updated);
    state = state.copyWith(comments: updated);
  }

  Future<void> deleteComment(String commentId, String currentUser) async {
    final updated = state.comments.where((c) {
      if (c.id == commentId && c.authorName == currentUser) return false;
      return true;
    }).toList();
    await LocalStorage.saveComments(articleId, updated);
    state = state.copyWith(comments: updated);
  }
}

final reactionsProvider =
    StateNotifierProvider.family<ReactionsNotifier, ReactionsState, String>(
  (ref, articleId) => ReactionsNotifier(articleId),
);
