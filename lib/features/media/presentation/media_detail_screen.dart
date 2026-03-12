import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/media_sources.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../features/news/domain/feed_news.dart';
import '../../../features/news/domain/media_source.dart';
import '../../../features/news/providers/news_providers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/subscription_provider.dart';
import '../../../shared/widgets/bonobo_article_image.dart';
import '../../../shared/widgets/bonobo_soft_toast.dart';
import '../../../shared/widgets/media_favicon.dart';

class MediaDetailScreen extends ConsumerWidget {
  final String sourceId;

  const MediaDetailScreen({super.key, required this.sourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = MediaSources.findById(sourceId);
    if (source == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E1118),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E1118),
          foregroundColor: Colors.white,
          title: const Text('Média introuvable'),
        ),
        body: const Center(
          child: Text('Ce média n\'existe pas.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final subscriptions = ref.watch(subscriptionProvider);
    final isSubscribed = subscriptions.contains(sourceId);
    final isAuth = ref.watch(authProvider).isAuthenticated;
    final articlesAsync = ref.watch(mediaDetailArticlesProvider(sourceId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarH = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E1118) : const Color(0xFFF2F4F7),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header avec favicon + infos média
            SliverToBoxAdapter(
              child: _MediaHeader(
                source: source,
                isSubscribed: isSubscribed,
                statusBarH: statusBarH,
                isDark: isDark,
                onSubscribeToggle: () {
                    if (!isAuth) {
                      BonoboSoftToast.show(context,
                        message: 'Connectez-vous pour suivre ce média.',
                        icon: Icons.lock_outline_rounded,
                        iconColor: Colors.orangeAccent,
                      );
                      context.push('/compte');
                      return;
                    }
                    ref.read(subscriptionProvider.notifier).toggle(sourceId);
                  },
                onOpenWebsite: () => _openWebsite(source),
              ),
            ),

            // ── Articles
            articlesAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ArticleSkeleton(isDark: isDark, large: i < 2),
                  childCount: 5,
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Indisponible hors connexion',
                  subtitle: 'Les articles de ${source.name} s\'afficheront dès que la connexion sera rétablie.',
                  isDark: isDark,
                  sourceColor: source.color,
                ),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      icon: Icons.article_outlined,
                      title: 'Aucun article disponible',
                      subtitle: 'Il n\'y a pas encore d\'articles de ${source.name} dans votre cache. Actualisez.',
                      isDark: isDark,
                      sourceColor: source.color,
                    ),
                  );
                }

                // Compteur d'articles dans l'en-tête
                return SliverMainAxisGroup(
                  slivers: [
                    // Section title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 20,
                              decoration: BoxDecoration(
                                color: source.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Actualités récentes',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.3,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: source.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${articles.length} articles',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: source.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Première carte — grande (image plein largeur)
                    if (articles.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _LargeArticleCard(
                          article: articles[0],
                          sourceColor: source.color,
                          isDark: isDark,
                        ),
                      ),

                    // Deuxième carte — grande
                    if (articles.length > 1)
                      SliverToBoxAdapter(
                        child: _LargeArticleCard(
                          article: articles[1],
                          sourceColor: source.color,
                          isDark: isDark,
                        ),
                      ),

                    // Divider entre les grands et les petits
                    if (articles.length > 2)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: source.color.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Autres articles',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Articles 2+ — cartes compactes horizontales
                    if (articles.length > 2)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _CompactArticleCard(
                            article: articles[i + 2],
                            sourceColor: source.color,
                            isDark: isDark,
                            index: i,
                          ),
                          childCount: articles.length - 2,
                        ),
                      ),
                  ],
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Future<void> _openWebsite(MediaSource source) async {
    try {
      final uri = Uri.parse(source.feedUrl);
      final siteUri = Uri.parse('${uri.scheme}://${uri.host}');
      await launchUrl(siteUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ─── Header média ─────────────────────────────────────────────────────────────
class _MediaHeader extends StatelessWidget {
  final MediaSource source;
  final bool isSubscribed;
  final double statusBarH;
  final bool isDark;
  final VoidCallback onSubscribeToggle;
  final VoidCallback onOpenWebsite;

  const _MediaHeader({
    required this.source,
    required this.isSubscribed,
    required this.statusBarH,
    required this.isDark,
    required this.onSubscribeToggle,
    required this.onOpenWebsite,
  });

  String get _domain {
    try {
      return Uri.parse(source.feedUrl).host.replaceFirst('www.', '');
    } catch (_) {
      return '';
    }
  }

  String get _feedTypeLabel {
    switch (source.feedType) {
      case FeedType.wordpress: return 'WordPress';
      case FeedType.rss: return 'RSS';
      case FeedType.drupal: return 'Drupal';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fond adaptatif : foncé en dark, blanc card avec légère teinte en clair
    final headerBg = isDark
        ? Color.lerp(const Color(0xFF111820), source.color, 0.06)!
        : Colors.white;
    final onHeader = isDark ? Colors.white : AppColors.textPrimary;
    final onHeaderSub = isDark ? Colors.white60 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: headerBg,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBar manuel
          SizedBox(
            height: statusBarH + kToolbarHeight,
            child: Padding(
              padding: EdgeInsets.only(top: statusBarH),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: onHeader,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    color: onHeaderSub,
                    onPressed: onOpenWebsite,
                    tooltip: 'Ouvrir le site',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),

          // Favicon + nom + infos
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Favicon grand format
                MediaFavicon(
                  faviconUrl: source.faviconUrl,
                  fallbackInitials: source.initials,
                  fallbackColor: source.color,
                  size: 72,
                  borderRadius: 20,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du média
                      Text(
                        source.name,
                        style: TextStyle(
                          color: onHeader,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Domain
                      Row(
                        children: [
                          Icon(Icons.link_rounded, size: 12, color: onHeaderSub),
                          const SizedBox(width: 4),
                          Text(
                            _domain,
                            style: TextStyle(
                              color: onHeaderSub,
                              fontSize: 12,
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
          ),

          const SizedBox(height: 20),

          // Badges : pays + type de flux + catégories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Pays
                _InfoBadge(
                  icon: Icons.flag_rounded,
                  label: source.countryLabel,
                  color: onHeader,
                  bgColor: onHeader.withValues(alpha: 0.1),
                ),
                // Type flux
                _InfoBadge(
                  icon: Icons.rss_feed_rounded,
                  label: _feedTypeLabel,
                  color: AppColors.primaryGreenStart.withValues(alpha: 0.9),
                  bgColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                ),
                // Catégories
                ...source.categories.map(
                  (cat) => _InfoBadge(
                    label: cat,
                    color: source.color.withValues(alpha: 0.9),
                    bgColor: source.color.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ligne de séparation + bouton S'abonner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : source.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : source.color.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                // Expanded = contrainte correcte, plus d'overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSubscribed ? 'Vous suivez ce média' : 'Suivre ce média',
                        style: TextStyle(
                          color: onHeader,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSubscribed
                            ? 'Vous recevrez les nouvelles alertes'
                            : 'Recevez les alertes de ${source.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onHeaderSub,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton S'abonner
                GestureDetector(
                  onTap: onSubscribeToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSubscribed
                          ? const LinearGradient(
                              colors: [Color(0xFF4ADE80), Color(0xFF01732C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSubscribed ? null : source.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSubscribed
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            key: ValueKey(isSubscribed),
                            size: 16,
                            color: isSubscribed
                                ? Colors.white
                                : (isDark ? Colors.white70 : source.color),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isSubscribed ? 'Abonné' : 'S\'abonner',
                          style: TextStyle(
                            color: isSubscribed
                                ? Colors.white
                                : (isDark ? Colors.white70 : source.color),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Séparateur bas du header
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
    );
  }
}

// ─── Badge info ───────────────────────────────────────────────────────────────
class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData? icon;

  const _InfoBadge({
    required this.label,
    required this.color,
    required this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grande carte article (plein largeur, image au dessus) ────────────────────
class _LargeArticleCard extends StatelessWidget {
  final FeedNews article;
  final Color sourceColor;
  final bool isDark;

  const _LargeArticleCard({
    required this.article,
    required this.sourceColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final category = article.category?.split(',').first.trim() ?? '';

    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161D2A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Stack(
                children: [
                  BonoboArticleImage(
                    imageUrl: article.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay bas
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Catégorie overlay
                  if (category.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sourceColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  // Temps relatif
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 10, color: Colors.white70),
                          const SizedBox(width: 3),
                          Text(
                            DateFormatter.relative(article.publishedAt),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu texte
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.3,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),

                  if (article.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Date + lire la suite
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          DateFormatter.full(article.publishedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Lire →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sourceColor,
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
      ),
    );
  }
}

// ─── Carte compacte (thumbnail gauche + titre droite) ─────────────────────────
class _CompactArticleCard extends StatelessWidget {
  final FeedNews article;
  final Color sourceColor;
  final bool isDark;
  final int index;

  const _CompactArticleCard({
    required this.article,
    required this.sourceColor,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numéro de rang
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${index + 3}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.grey.shade300,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.35,
                            color: isDark ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                            if (article.category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: sourceColor.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                article.category!.split(',').first.trim(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: sourceColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BonoboArticleImage(
                      imageUrl: article.imageUrl,
                      width: 72,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color sourceColor;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.sourceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: sourceColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: sourceColor, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton loading ─────────────────────────────────────────────────────────
class _ArticleSkeleton extends StatelessWidget {
  final bool isDark;
  final bool large;

  const _ArticleSkeleton({required this.isDark, this.large = false});

  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade300;

    if (large) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 16, width: double.infinity,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(height: 16, width: 240,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 10),
            Container(height: 11, width: 140,
                decoration: BoxDecoration(color: base.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4))),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SizedBox(width: 32, child: Container(height: 20, width: 20,
              decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: double.infinity,
                    decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 5),
                Container(height: 13, width: 200,
                    decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 7),
                Container(height: 10, width: 100,
                    decoration: BoxDecoration(color: base.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 72, height: 60,
              decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10))),
        ],
      ),
    );
  }
}
