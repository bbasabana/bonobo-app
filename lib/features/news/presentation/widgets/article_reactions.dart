import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/local_storage.dart';
import '../../../../shared/models/local_reaction.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/reactions_provider.dart';
import '../../../../shared/widgets/bonobo_soft_toast.dart';

/// Section réactions complète : likes animés + commentaires style Facebook.
class ArticleReactionsSection extends ConsumerStatefulWidget {
  final String articleId;
  final String articleTitle;
  final Color accentColor;
  /// Déclenché depuis la barre flottante pour ouvrir le champ commentaire.
  final ValueNotifier<bool>? externalCommentTrigger;

  const ArticleReactionsSection({
    super.key,
    required this.articleId,
    required this.articleTitle,
    required this.accentColor,
    this.externalCommentTrigger,
  });

  @override
  ConsumerState<ArticleReactionsSection> createState() => _ArticleReactionsSectionState();
}

class _ArticleReactionsSectionState extends ConsumerState<ArticleReactionsSection>
    with TickerProviderStateMixin {
  final _commentController = TextEditingController();
  bool _showCommentInput = false;
  final _focusNode = FocusNode();

  // Particules d'animation like
  late AnimationController _likeAnimCtrl;
  final List<_Particle> _particles = [];
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _likeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _showParticles = false);
        _likeAnimCtrl.reset();
      }
    });

    // Écouter le trigger externe (barre flottante)
    widget.externalCommentTrigger?.addListener(_onExternalCommentTrigger);
  }

  void _onExternalCommentTrigger() {
    if (!mounted) return;
    setState(() => _showCommentInput = true);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.externalCommentTrigger?.removeListener(_onExternalCommentTrigger);
    _commentController.dispose();
    _focusNode.dispose();
    _likeAnimCtrl.dispose();
    super.dispose();
  }

  void _triggerLikeAnimation() {
    final rng = Random();
    _particles.clear();
    for (int i = 0; i < 10; i++) {
      _particles.add(_Particle(
        angle: rng.nextDouble() * 2 * pi,
        speed: 30 + rng.nextDouble() * 60,
        color: [
          AppColors.primaryGreenStart,
          Colors.amber,
          Colors.pinkAccent,
          Colors.cyanAccent,
        ][rng.nextInt(4)],
        size: 4 + rng.nextDouble() * 5,
      ));
    }
    setState(() => _showParticles = true);
    _likeAnimCtrl.forward(from: 0);
  }

  bool get _isAuth => ref.read(authProvider).isAuthenticated;

  String get _currentUser {
    final token = LocalStorage.getToken();
    if (token != null) return 'Vous';
    return 'Visiteur';
  }

  void _requireAuth(VoidCallback action) {
    if (!_isAuth) {
      BonoboSoftToast.show(context,
        message: 'Connectez-vous pour effectuer cette action.',
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.orangeAccent,
      );
      return;
    }
    action();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (!_isAuth) {
      BonoboSoftToast.show(context,
        message: 'Connectez-vous pour commenter.',
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.orangeAccent,
      );
      return;
    }
    await ref.read(reactionsProvider(widget.articleId).notifier).addComment(_currentUser, text);
    _commentController.clear();
    setState(() => _showCommentInput = false);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reactionsProvider(widget.articleId));
    final reaction = state.reaction;
    final comments = state.comments;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final cardColor = isDark ? const Color(0xFF1A1D2C) : Colors.white;
    final divColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Réactions',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(width: 8),
              if (comments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${comments.length}',
                    style: TextStyle(color: widget.accentColor, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),

        // ── Barre réactions (like / dislike / commenter / partager)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divColor),
            ),
            child: Row(
              children: [
                // Like avec animation particules
                Expanded(
                  child: GestureDetector(
                    onTap: () => _requireAuth(() async {
                      await ref.read(reactionsProvider(widget.articleId).notifier).toggleLike();
                      if (!reaction.isLiked) _triggerLikeAnimation();
                    }),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _ReactionBtn(
                          icon: reaction.isLiked
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          label: reaction.totalLikes > 0 ? '${reaction.totalLikes}' : 'J\'aime',
                          color: reaction.isLiked ? AppColors.primaryGreenStart : subColor,
                          active: reaction.isLiked,
                        ),
                        if (_showParticles)
                          AnimatedBuilder(
                            animation: _likeAnimCtrl,
                            builder: (_, __) => _ParticleBurst(
                              particles: _particles,
                              progress: _likeAnimCtrl.value,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _Divider(color: divColor),
                // Dislike
                Expanded(
                  child: GestureDetector(
                    onTap: () => _requireAuth(
                      () => ref.read(reactionsProvider(widget.articleId).notifier).toggleDislike()),
                    child: _ReactionBtn(
                      icon: reaction.isDisliked
                          ? Icons.thumb_down_rounded
                          : Icons.thumb_down_outlined,
                      label: 'Pas utile',
                      color: reaction.isDisliked ? Colors.redAccent : subColor,
                      active: reaction.isDisliked,
                    ),
                  ),
                ),
                _Divider(color: divColor),
                // Commenter
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showCommentInput = !_showCommentInput);
                      if (_showCommentInput) {
                        Future.delayed(const Duration(milliseconds: 100), () => _focusNode.requestFocus());
                      }
                    },
                    child: _ReactionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Commenter',
                      color: _showCommentInput ? widget.accentColor : subColor,
                      active: _showCommentInput,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Champ de saisie commentaire
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showCommentInput
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Avatar(name: _currentUser, color: widget.accentColor, size: 32),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                focusNode: _focusNode,
                                maxLines: 3,
                                minLines: 1,
                                style: TextStyle(color: textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Votre commentaire…',
                                  hintStyle: TextStyle(color: subColor, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _showCommentInput = false);
                                _commentController.clear();
                                _focusNode.unfocus();
                              },
                              style: TextButton.styleFrom(foregroundColor: subColor),
                              child: const Text('Annuler', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _submitComment,
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.accentColor,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Publier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ── Liste des commentaires
        if (comments.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...comments.map((c) => _CommentCard(
            comment: c,
            accentColor: widget.accentColor,
            isDark: isDark,
            currentUser: _currentUser,
            onLike: () => ref.read(reactionsProvider(widget.articleId).notifier).likeComment(c.id),
            onDelete: () => ref.read(reactionsProvider(widget.articleId).notifier).deleteComment(c.id, _currentUser),
          )),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 18, color: isDark ? Colors.white24 : Colors.grey.shade400),
                const SizedBox(width: 10),
                Text(
                  'Soyez le premier à commenter cet article.',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Bouton réaction ──────────────────────────────────────────────────────────
class _ReactionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  const _ReactionBtn({required this.icon, required this.label, required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: active ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: color);
}

// ─── Carte commentaire ────────────────────────────────────────────────────────
class _CommentCard extends StatelessWidget {
  final LocalComment comment;
  final Color accentColor;
  final bool isDark;
  final String currentUser;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _CommentCard({
    required this.comment,
    required this.accentColor,
    required this.isDark,
    required this.currentUser,
    required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final cardColor = isDark ? const Color(0xFF1A1D2C) : Colors.white;
    final divColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : avatar + nom + date
            Row(
              children: [
                _Avatar(name: comment.authorName, color: accentColor, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.authorName, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(DateFormatter.relative(comment.createdAt), style: TextStyle(color: subColor, fontSize: 11)),
                    ],
                  ),
                ),
                if (comment.authorName == currentUser)
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent.withValues(alpha: 0.7)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Texte
            Text(comment.text, style: TextStyle(color: textColor, fontSize: 13, height: 1.45)),
            const SizedBox(height: 8),
            // Actions
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          comment.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(comment.isLikedByMe),
                          size: 16,
                          color: comment.isLikedByMe ? Colors.pinkAccent : subColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comment.likes > 0 ? '${comment.likes}' : 'J\'aime',
                        style: TextStyle(
                          fontSize: 11,
                          color: comment.isLikedByMe ? Colors.pinkAccent : subColor,
                          fontWeight: comment.isLikedByMe ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar initiales ─────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const _Avatar({required this.name, required this.color, required this.size});

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(_initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.42)),
      ),
    );
  }
}

// ─── Burst de particules like ─────────────────────────────────────────────────
class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;
  const _Particle({required this.angle, required this.speed, required this.color, required this.size});
}

class _ParticleBurst extends StatelessWidget {
  final List<_Particle> particles;
  final double progress;
  const _ParticleBurst({required this.particles, required this.progress});

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: particles.map((p) {
          final dist = p.speed * progress;
          final dx = cos(p.angle) * dist;
          final dy = sin(p.angle) * dist;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: p.size,
                height: p.size,
                decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
