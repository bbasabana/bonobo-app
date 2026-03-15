import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
// import '../../../../core/constants/media_sources.dart'; // No longer needed
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/share_helper.dart';
import '../../../../shared/local_storage.dart';
import '../../../../shared/widgets/bonobo_soft_toast.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/saved_articles_provider.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/providers/reactions_provider.dart';
import '../../domain/feed_news.dart';
import '../../providers/news_providers.dart';
import '../widgets/article_reactions.dart';
import '../../../../shared/providers/marketing_provider.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String articleId;
  final Map<String, dynamic>? extra;

  const ArticleDetailScreen({
    super.key,
    required this.articleId,
    this.extra,
  });

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen>
    with SingleTickerProviderStateMixin {
  FeedNews? _article;
  bool _hasTrackedView = false;
  late double _fontSize;

  // Scroll pour la barre de titre qui apparaît
  final _scrollController = ScrollController();
  bool _titleVisible = false;

  @override
  void initState() {
    super.initState();
    // Charger la taille de police sauvegardée (persistée en local)
    _fontSize = LocalStorage.getArticleFontSize();
    if (widget.extra?['article'] != null) {
      _article = FeedNews.fromJson(
        Map<String, dynamic>.from(widget.extra!['article'] as Map),
      );
    }
    _scrollController.addListener(() {
      const threshold = 260.0;
      final nowVisible = _scrollController.offset > threshold;
      if (nowVisible != _titleVisible) {
        setState(() => _titleVisible = nowVisible);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _trackView() {
    final a = _article;
    if (a == null) return;
    ref.read(analyticsServiceProvider).trackArticleView(a);
  }

  Future<void> _share() async {
    if (_article == null) return;
    ref.read(analyticsServiceProvider).trackArticleShare(_article!, shareMethod: 'link');
    await Share.share(
      BonoboShareHelper.buildShareText(
        title: _article!.title,
        url: _article!.originalUrl,
        excerpt: _article!.excerpt.isNotEmpty ? _article!.excerpt : null,
        sourceName: _article!.sourceName,
      ),
      subject: BonoboShareHelper.buildSubject(_article!.title),
    );
  }

  Future<void> _openSource() async {
    if (_article == null) return;
    final url = _article!.originalUrl.trim();
    if (url.isEmpty) {
      if (mounted) {
        BonoboSoftToast.show(context,
          message: 'Lien source non disponible pour cet article.',
          icon: Icons.link_off_rounded,
          iconColor: Colors.orangeAccent,
        );
      }
      return;
    }
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Si externalApplication échoue, essayer en mode navigateur intégré
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        if (mounted) {
          BonoboSoftToast.show(context,
            message: 'Impossible d\'ouvrir le lien. Copiez-le manuellement.',
            icon: Icons.error_outline_rounded,
            iconColor: Colors.redAccent,
          );
        }
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_article == null) return;
    ref.read(analyticsServiceProvider).trackArticleShare(_article!, shareMethod: 'pdf');
    try {
      BonoboSoftToast.show(context,
        message: 'Génération du PDF en cours…',
        icon: Icons.picture_as_pdf_rounded,
        iconColor: AppColors.primaryGreenStart,
      );
      final file = await PdfExportService().generateArticlePdf(_article!);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: BonoboShareHelper.buildPdfShareText(_article!.title),
        subject: BonoboShareHelper.buildSubject(_article!.title),
      );
    } catch (_) {
      if (mounted) {
        BonoboSoftToast.show(context,
          message: 'Erreur lors de la génération du PDF.',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  Future<void> _saveArticle() async {
    if (!ref.read(authProvider).isAuthenticated) {
      BonoboSoftToast.show(context,
        message: 'Connectez-vous pour sauvegarder des articles.',
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.orangeAccent,
      );
      context.push('/compte');
      return;
    }
    final article = _article;
    if (article == null) return;
    final added = await ref.read(savedArticlesProvider.notifier).toggle(article);
    if (!mounted) return;
    BonoboSoftToast.show(context,
      message: added
          ? 'Article sauvegardé dans votre bibliothèque.'
          : 'Article retiré de votre bibliothèque.',
      icon: added ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
      iconColor: added ? AppColors.primaryGreenStart : Colors.orangeAccent,
    );
  }

  void _copyLink() {
    if (_article == null) return;
    // Copie le lien avec la signature Bonobo
    final text = '${_article!.originalUrl}\n\n${BonoboShareHelper.buildPdfShareText(_article!.title)}';
    Clipboard.setData(ClipboardData(text: text));
    BonoboSoftToast.show(context,
      message: 'Lien copié avec signature Bonobo.',
      icon: Icons.copy_rounded,
      iconColor: AppColors.primaryGreenStart,
    );
  }

  void _showMoreActions() {
    if (_article == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return _MoreActionsSheet(
            article: _article!,
            onExportPdf: () { Navigator.pop(ctx); _exportPdf(); },
            onCopyLink: () { Navigator.pop(ctx); _copyLink(); },
            onOpenSource: () { Navigator.pop(ctx); _openSource(); },
            onFontSmaller: () {
              final newSize = (_fontSize - 1.0).clamp(13.0, 22.0);
              setState(() => _fontSize = newSize);
              setSheetState(() {});
              LocalStorage.saveArticleFontSize(newSize);
            },
            onFontLarger: () {
              final newSize = (_fontSize + 1.0).clamp(13.0, 22.0);
              setState(() => _fontSize = newSize);
              setSheetState(() {});
              LocalStorage.saveArticleFontSize(newSize);
            },
            currentFontSize: _fontSize,
          );
        },
      ),
    );
  }

  // Notifie ArticleReactionsSection pour ouvrir le champ commentaire
  final _commentTrigger = ValueNotifier<bool>(false);

  void _requestComment() {
    _commentTrigger.value = !_commentTrigger.value;
    // Scroll vers les réactions
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_article != null && !_hasTrackedView) {
      _hasTrackedView = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(analyticsServiceProvider).trackArticleView(_article!);
          ref.read(marketingProvider.notifier).incrementArticleViews();
          _trackView();
        }
      });
    }

    if (_article == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E1118),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Article introuvable', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final article = _article!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sources = ref.watch(mediaSourcesMapProvider);
    final source = sources[article.sourceId];
    final sourceColor = source?.color ?? AppColors.primaryGreen;
    final subscriptions = ref.watch(subscriptionProvider);
    final isSubscribed = subscriptions.contains(article.sourceId);
    final statusBarH = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final categoryLabel = article.category?.split(',').first.trim() ?? '';
    final savedIds = ref.watch(savedArticlesProvider);
    final isSaved = savedIds.contains(article.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E1118) : const Color(0xFFF2F4F7),
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context, article, isSubscribed, isDark, statusBarH, isSaved: isSaved, onSave: _saveArticle),
        body: Stack(
          children: [
            // ── Contenu scrollable
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero image
                SliverToBoxAdapter(
                  child: _HeroSection(
                    article: article,
                    categoryLabel: categoryLabel,
                    sourceColor: sourceColor,
                    statusBarH: statusBarH,
                  ),
                ),

                // Contenu
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0E1118) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: Text(
                            article.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              height: 1.35,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),

                        // Méta : date + source
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 13,
                                  color: isDark ? Colors.white38 : Colors.grey.shade400),
                              const SizedBox(width: 5),
                              Text(
                                DateFormatter.full(article.publishedAt),
                                style: TextStyle(fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors.grey.shade500),
                              ),
                              const SizedBox(width: 8),
                              Container(width: 3, height: 3,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  )),
                              const SizedBox(width: 8),
                              Text(
                                DateFormatter.relative(article.publishedAt),
                                style: TextStyle(fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),

                        // Divider fin
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1,
                              color: isDark ? Colors.white10 : Colors.grey.shade100),
                        ),

                        // Corps de l'article (directement après le titre)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: _ArticleBody(
                            content: article.content.isNotEmpty
                                ? article.content
                                : article.excerpt,
                            fontSize: _fontSize,
                            isDark: isDark,
                          ),
                        ),

                        // Emplacement publicitaire (compact)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _AdBanner(isDark: isDark),
                        ),

                        // Bouton lire la suite
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: _ReadMoreButton(
                            sourceName: article.sourceName,
                            sourceColor: sourceColor,
                            onTap: _openSource,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Réactions (likes + commentaires)
                SliverToBoxAdapter(
                  child: ArticleReactionsSection(
                    articleId: article.id,
                    articleTitle: article.title,
                    accentColor: sourceColor,
                    externalCommentTrigger: _commentTrigger,
                  ),
                ),

                // Articles du même média (titre + liste dans _RelatedArticles)
                _RelatedArticles(
                  sourceId: article.sourceId,
                  currentId: article.id,
                  sourceColor: sourceColor,
                  isDark: isDark,
                  sourceName: article.sourceName,
                ),

                // Espace sous la barre flottante
                SliverToBoxAdapter(child: SizedBox(height: 90 + bottomPad)),
              ],
            ),

            // ── Barre d'engagement flottante (bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _FloatingEngagementBar(
                article: article,
                sourceColor: sourceColor,
                bottomPad: bottomPad,
                onShare: _share,
                onComment: _requestComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext ctx, FeedNews article,
      bool isSubscribed, bool isDark, double statusBarH,
      {required bool isSaved, required VoidCallback onSave}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: _titleVisible
            ? AppColors.backgroundDark.withValues(alpha: 0.97)
            : Colors.transparent,
        child: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: AnimatedOpacity(
            opacity: _titleVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 24,
              ),
              onPressed: onSave,
              tooltip: isSaved ? 'Retirer des sauvegardes' : 'Sauvegarder l\'article',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 22),
              onPressed: _showMoreActions,
              tooltip: 'Plus d\'options',
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Barre d'engagement flottante ────────────────────────────────────────────
class _FloatingEngagementBar extends ConsumerWidget {
  final FeedNews article;
  final Color sourceColor;
  final double bottomPad;
  final VoidCallback onShare;
  final VoidCallback onComment;

  const _FloatingEngagementBar({
    required this.article,
    required this.sourceColor,
    required this.bottomPad,
    required this.onShare,
    required this.onComment,
  });

  void _requireAuth(BuildContext ctx, WidgetRef ref, VoidCallback action) {
    if (!ref.read(authProvider).isAuthenticated) {
      BonoboSoftToast.show(ctx,
        message: 'Connectez-vous pour effectuer cette action.',
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.orangeAccent,
      );
      ctx.push('/compte');
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactState = ref.watch(reactionsProvider(article.id));
    final reaction = reactState.reaction;
    final commentCount = reactState.comments.length;
    final isAuth = ref.watch(authProvider).isAuthenticated;

    const Color inactiveColor = Color(0xFFB8BEC8);
    const Color lockedColor = Color(0xFF666C7A);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF20D1117),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2430), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── J'aime
          Expanded(
            child: _EngageBtn(
              icon: reaction.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: reaction.totalLikes > 0
                  ? '${reaction.totalLikes} J\'aime'
                  : 'J\'aime',
              activeColor: Colors.pinkAccent,
              inactiveColor: inactiveColor,
              lockedColor: lockedColor,
              active: reaction.isLiked,
              locked: !isAuth,
              onTap: () => _requireAuth(context, ref,
                () => ref.read(reactionsProvider(article.id).notifier).toggleLike()),
            ),
          ),

          // ── Pas utile
          Expanded(
            child: _EngageBtn(
              icon: reaction.isDisliked
                  ? Icons.thumb_down_rounded
                  : Icons.thumb_down_outlined,
              label: 'Pas utile',
              activeColor: Colors.orangeAccent,
              inactiveColor: inactiveColor,
              lockedColor: lockedColor,
              active: reaction.isDisliked,
              locked: !isAuth,
              onTap: () => _requireAuth(context, ref,
                () => ref.read(reactionsProvider(article.id).notifier).toggleDislike()),
            ),
          ),

          // ── Commenter
          Expanded(
            child: _EngageBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: commentCount > 0 ? '$commentCount comm.' : 'Commenter',
              activeColor: const Color(0xFF64B5F6),
              inactiveColor: inactiveColor,
              lockedColor: lockedColor,
              active: false,
              locked: !isAuth,
              onTap: () => _requireAuth(context, ref, onComment),
            ),
          ),

          const SizedBox(width: 8),

          // ── Partager — cercle icône (footer)
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ADE80), Color(0xFF01732C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EngageBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color activeColor;
  final Color inactiveColor;
  final Color lockedColor;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  const _EngageBtn({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.inactiveColor,
    required this.lockedColor,
    required this.active,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = locked
        ? lockedColor
        : active
            ? activeColor
            : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: active ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(icon, size: 22, color: effectiveColor),
                ),
                if (locked)
                  Positioned(
                    right: -5,
                    bottom: -3,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D1117),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 7,
                        color: Color(0xFF666C7A),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: effectiveColor,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
                height: 1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero section ─────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final FeedNews article;
  final String categoryLabel;
  final Color sourceColor;
  final double statusBarH;

  const _HeroSection({
    required this.article,
    required this.categoryLabel,
    required this.sourceColor,
    required this.statusBarH,
  });

  @override
  Widget build(BuildContext context) {
    final heroHeight = 280.0 + statusBarH;
    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Image.asset(
                    'assets/images/bonobo_load_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/images/bonobo_load_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset('assets/images/bonobo_load_bg.jpg', fit: BoxFit.cover),

          // Gradient sombre de bas en haut (lisibilité)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [0.45, 1.0],
              ),
            ),
          ),

          // Gradient en haut (pour l'AppBar transparent)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
                ),
              ),
            ),
          ),

          // Badges source + catégorie + temps en bas de l'image
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Badge source coloré
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sourceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    article.sourceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (categoryLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      categoryLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Temps relatif
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.relative(article.publishedAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barre d'actions ──────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final FeedNews article;
  final bool isSubscribed;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onMore;
  final VoidCallback onSubscribeToggle;
  final Color sourceColor;

  const _ActionBar({
    required this.article,
    required this.isSubscribed,
    required this.onShare,
    required this.onSave,
    required this.onMore,
    required this.onSubscribeToggle,
    required this.sourceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionItem(
            icon: Icons.share_rounded,
            label: 'Partager',
            color: AppColors.primaryGreenStart,
            onTap: onShare,
          ),
          _ActionItem(
            icon: Icons.bookmark_add_outlined,
            label: 'Sauvegarder',
            color: Colors.blueAccent,
            onTap: onSave,
          ),
          _ActionItem(
            icon: isSubscribed
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            label: isSubscribed ? 'Suivi' : 'Suivre',
            color: isSubscribed ? sourceColor : Colors.white60,
            onTap: onSubscribeToggle,
            isActive: isSubscribed,
          ),
          _ActionItem(
            icon: Icons.more_horiz_rounded,
            label: 'Plus',
            color: Colors.white60,
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: isActive ? color : Colors.white70),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? color : Colors.white54,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Corps de l'article ───────────────────────────────────────────────────────
class _ArticleBody extends StatelessWidget {
  final String content;
  final double fontSize;
  final bool isDark;

  const _ArticleBody({
    required this.content,
    required this.fontSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Séparer les paragraphes pour un meilleur rendu
    final paragraphs = content
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return Text(
        content,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.8,
          color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1A1A2E),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final i = entry.key;
        final para = entry.value;
        // Premier paragraphe en lead
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              para,
              style: TextStyle(
                fontSize: fontSize + 1,
                height: 1.65,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A1A2E),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            para,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.7,
              color: isDark ? Colors.white.withValues(alpha: 0.82) : const Color(0xFF2D2D2D),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Bannière publicitaire (emplacement réservé) ─────────────────────────────
class _AdBanner extends StatelessWidget {
  final bool isDark;
  const _AdBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_rounded, size: 15,
              color: isDark ? Colors.white24 : Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            'Espace publicitaire',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton "Lire la suite" ───────────────────────────────────────────────────
class _ReadMoreButton extends StatelessWidget {
  final String sourceName;
  final Color sourceColor;
  final VoidCallback onTap;

  const _ReadMoreButton({
    required this.sourceName,
    required this.sourceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sourceColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sourceColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sourceColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.open_in_new_rounded, size: 18, color: sourceColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lire l\'article complet',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: sourceColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ouvrir sur $sourceName',
                    style: TextStyle(
                      fontSize: 12,
                      color: sourceColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: sourceColor.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet "Plus d'actions" ───────────────────────────────────────────────────
class _MoreActionsSheet extends StatelessWidget {
  final FeedNews article;
  final VoidCallback onExportPdf;
  final VoidCallback onCopyLink;
  final VoidCallback onOpenSource;
  final VoidCallback onFontSmaller;
  final VoidCallback onFontLarger;
  final double currentFontSize;

  const _MoreActionsSheet({
    required this.article,
    required this.onExportPdf,
    required this.onCopyLink,
    required this.onOpenSource,
    required this.onFontSmaller,
    required this.onFontLarger,
    required this.currentFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Options',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),

          // Taille du texte
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.text_fields_rounded, color: Colors.white60, size: 20),
                const SizedBox(width: 12),
                const Text('Taille du texte',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                _FontBtn(icon: Icons.remove_rounded, onTap: onFontSmaller),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currentFontSize.toInt()}',
                    style: const TextStyle(color: AppColors.primaryGreenStart, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                _FontBtn(icon: Icons.add_rounded, onTap: onFontLarger),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _SheetAction(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Exporter en PDF',
            subtitle: 'Partager l\'article en PDF signé Bonobo',
            color: Colors.redAccent,
            onTap: onExportPdf,
          ),
          _SheetAction(
            icon: Icons.link_rounded,
            label: 'Copier le lien',
            subtitle: article.originalUrl,
            color: Colors.blueAccent,
            onTap: onCopyLink,
          ),
          _SheetAction(
            icon: Icons.open_in_browser_rounded,
            label: 'Ouvrir dans le navigateur',
            subtitle: 'Voir l\'article sur le site source',
            color: Colors.white60,
            onTap: onOpenSource,
          ),
        ],
      ),
    );
  }
}

class _FontBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FontBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Articles similaires (avec header conditionnel intégré) ──────────────────
class _RelatedArticles extends ConsumerWidget {
  final String sourceId;
  final String sourceName;
  final String currentId;
  final Color sourceColor;
  final bool isDark;

  const _RelatedArticles({
    required this.sourceId,
    required this.sourceName,
    required this.currentId,
    required this.sourceColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(newsForSourceProvider(sourceId));

    return articlesAsync.when(
      // Pendant le chargement : afficher le header + skeletons
      loading: () => SliverMainAxisGroup(
        slivers: [
          _header(context),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _RelatedArticleSkeleton(isDark: isDark),
              childCount: 3,
            ),
          ),
        ],
      ),
      // Erreur : rien du tout
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (articles) {
        final related = articles.where((a) => a.id != currentId).take(5).toList();
        // Aucun article disponible → ne rien afficher (ni titre, ni bloc vide)
        if (related.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverMainAxisGroup(
          slivers: [
            _header(context),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _RelatedArticleCard(
                  article: related[i],
                  sourceColor: sourceColor,
                  isDark: isDark,
                ),
                childCount: related.length,
              ),
            ),
          ],
        );
      },
    );
  }

  SliverToBoxAdapter _header(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: sourceColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Plus de $sourceName',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/media/$sourceId'),
              child: Text(
                'Voir tout',
                style: TextStyle(
                  fontSize: 13,
                  color: sourceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte article similaire ──────────────────────────────────────────────────
class _RelatedArticleCard extends StatelessWidget {
  final FeedNews article;
  final Color sourceColor;
  final bool isDark;

  const _RelatedArticleCard({
    required this.article,
    required this.sourceColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D2C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      width: 80,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 80, height: 70,
                        color: sourceColor.withValues(alpha: 0.1),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80, height: 70,
                        color: sourceColor.withValues(alpha: 0.1),
                        child: Icon(Icons.image_not_supported_outlined,
                            color: sourceColor.withValues(alpha: 0.4), size: 24),
                      ),
                    )
                  : Container(
                      width: 80, height: 70,
                      decoration: BoxDecoration(
                        color: sourceColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          article.sourceName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: sourceColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Titre + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.35,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.relative(article.publishedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton chargement ──────────────────────────────────────────────────────
class _RelatedArticleSkeleton extends StatelessWidget {
  final bool isDark;
  const _RelatedArticleSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(width: 80, height: 70, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 12, width: 200, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 10, width: 80, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
