import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../data/comment_service.dart';
import '../domain/comment.dart';

final commentServiceProvider = Provider<CommentService>((ref) {
  final token = ref.watch(authProvider).token;
  return CommentService(token: token);
});

final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, articleId) async {
  final service = ref.watch(commentServiceProvider);
  return service.fetchComments(articleId);
});

class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  final CommentService _service;
  final Ref _ref;

  CommentNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<bool> postComment(String articleId, String content) async {
    state = const AsyncValue.loading();
    try {
      final success = await _service.postComment(articleId, content);
      if (success) {
        state = const AsyncValue.data(null);
        _ref.invalidate(commentsProvider(articleId));
        return true;
      } else {
        state = AsyncValue.error('Erreur lors de l\'envoi', StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final commentActionProvider = StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(commentServiceProvider);
  return CommentNotifier(service, ref);
});
