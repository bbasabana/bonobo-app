import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_config.dart';
import '../local_storage.dart';
import '../models/local_reaction.dart';
import './auth_provider.dart';

// ─── État réactions d'un article ─────────────────────────────────────────────
class ReactionsState {
  final ArticleReaction reaction;
  final List<dynamic> comments;
  final bool isLoading;

  const ReactionsState({
    required this.reaction,
    this.comments = const [],
    this.isLoading = false,
  });

  ReactionsState copyWith({
    ArticleReaction? reaction,
    List<dynamic>? comments,
    bool? isLoading,
  }) =>
      ReactionsState(
        reaction: reaction ?? this.reaction,
        comments: comments ?? this.comments,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ReactionsNotifier extends StateNotifier<ReactionsState> {
  final String articleId;
  final Ref _ref;
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  ReactionsNotifier(this.articleId, this._ref)
      : super(ReactionsState(
          reaction: LocalStorage.getReaction(articleId),
          comments: LocalStorage.getComments(articleId),
        )) {
    _init();
  }

  Future<void> _init() async {
    await fetchReactions();
  }

  Future<void> fetchReactions() async {
    try {
      final token = _ref.read(authProvider).token;
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final res = await _dio.get(
        '/api/v1/articles/$articleId/interaction',
        options: options,
      );

      if (res.statusCode == 200) {
        final data = res.data;
        final newReaction = ArticleReaction(
          articleId: articleId,
          isLiked: data['userInteraction'] == 'like',
          isDisliked: data['userInteraction'] == 'dislike',
          totalLikes: (data['likes'] as num?)?.toInt() ?? 0,
        );
        LocalStorage.saveReaction(newReaction);
        state = state.copyWith(reaction: newReaction);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Reactions] Error fetching: $e');
    }
  }

  Future<void> toggleLike() async {
    await _handleInteraction('like');
  }

  Future<void> toggleDislike() async {
    await _handleInteraction('dislike');
  }

  Future<void> _handleInteraction(String type) async {
    final token = _ref.read(authProvider).token;
    if (token == null) return;

    // Optimistic update
    final current = state.reaction;
    bool newIsLiked = current.isLiked;
    bool newIsDisliked = current.isDisliked;
    int newTotalLikes = current.totalLikes;

    if (type == 'like') {
      if (current.isLiked) {
        newIsLiked = false;
        newTotalLikes = (newTotalLikes - 1).clamp(0, 999999);
      } else {
        newIsLiked = true;
        newTotalLikes++;
        if (current.isDisliked) newIsDisliked = false;
      }
    } else if (type == 'dislike') {
      if (current.isDisliked) {
        newIsDisliked = false;
      } else {
        newIsDisliked = true;
        if (current.isLiked) {
          newIsLiked = false;
          newTotalLikes = (newTotalLikes - 1).clamp(0, 999999);
        }
      }
    }

    final optimistic = current.copyWith(
      isLiked: newIsLiked,
      isDisliked: newIsDisliked,
      totalLikes: newTotalLikes,
    );
    state = state.copyWith(reaction: optimistic);

    try {
      await _dio.post(
        '/api/v1/articles/$articleId/interaction',
        data: {'type': type},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Re-fetch to sync with server exactly
      await fetchReactions();
    } catch (e) {
      if (kDebugMode) debugPrint('[Reactions] Error interaction: $e');
      // Revert if error
      state = state.copyWith(reaction: current);
    }
  }

  Future<void> addComment(String authorName, String text) async {
    // Logic moved to CommentNotifier in comment_providers.dart
    // Use ref.read(commentActionProvider.notifier).postComment(...)
  }

  Future<void> likeComment(String commentId) async {
    // To be implemented on backend later
  }

  Future<void> deleteComment(String commentId, String currentUser) async {
    // To be implemented on backend later
  }
}

final reactionsProvider =
    StateNotifierProvider.family<ReactionsNotifier, ReactionsState, String>(
  (ref, articleId) => ReactionsNotifier(articleId, ref),
);
