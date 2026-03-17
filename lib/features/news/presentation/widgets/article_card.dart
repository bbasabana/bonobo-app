import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
// import '../../../../core/constants/media_sources.dart';
import '../../providers/news_providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/bonobo_article_image.dart';
import '../../domain/feed_news.dart';

enum ArticleCardStyle { standard, compact, condensed }

// ─────────────────────────────────────────────
//  ArticleCard (legacy list card — kept for compatibility)
// ─────────────────────────────────────────────
class ArticleCard extends ConsumerWidget {
  final FeedNews article;
  final ArticleCardStyle style;
  final bool showBadge;

  const ArticleCard({
    super.key,
    required this.article,
    this.style = ArticleCardStyle.standard,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (style == ArticleCardStyle.condensed) {
      return ArticleCondensedCard(article: article);
    }
    return ArticleListCard(article: article, showBadge: showBadge);
  }
}

// ─────────────────────────────────────────────
//  ArticleGridCard — High-end E-commerce Style
// ─────────────────────────────────────────────
class ArticleGridCard extends ConsumerWidget {
  final FeedNews article;

  const ArticleGridCard({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sources = ref.watch(mediaSourcesMapProvider);
    final source = sources[article.sourceId];
    final sourceColor = source?.color ?? AppColors.primaryGreen;

    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BonoboArticleImage(
                    imageUrl: article.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for bottom tag
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Source Tag
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sourceColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: sourceColor.withValues(alpha: 0.3), blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            source?.name.toUpperCase() ?? article.sourceName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (source?.certificationIcon != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              source!.certificationIcon,
                              size: 10,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.3,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 11,
                      color: AppColors.primaryGreenStart.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        DateFormatter.relative(article.publishedAt).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 16,
                      color: isDark ? Colors.white30 : Colors.black12,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ArticleListCard — Clean & Refined
// ─────────────────────────────────────────────
class ArticleListCard extends ConsumerWidget {
  final FeedNews article;
  final bool showBadge;

  const ArticleListCard({super.key, required this.article, this.showBadge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sources = ref.watch(mediaSourcesMapProvider);
    final source = sources[article.sourceId];
    final sourceColor = source?.color ?? AppColors.primaryGreen;

    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B26) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image vignette
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: BonoboArticleImage(
                imageUrl: article.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sourceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              article.sourceName.toUpperCase(),
                              style: TextStyle(
                                color: sourceColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (source?.certificationIcon != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                source!.certificationIcon,
                                size: 11,
                                color: sourceColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 8),
                        const CircleAvatar(radius: 2, backgroundColor: AppColors.primaryGreenStart),
                        const SizedBox(width: 4),
                        const Text(
                          'RÉCENT',
                          style: TextStyle(color: AppColors.primaryGreenStart, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.3,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.flash_on_rounded, size: 12, color: sourceColor.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.relative(article.publishedAt),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.textSecondary),
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

// ─────────────────────────────────────────────
//  ArticleFeaturedCard — Cinematic Full Width
// ─────────────────────────────────────────────
class ArticleFeaturedCard extends ConsumerWidget {
  final FeedNews article;

  const ArticleFeaturedCard({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sources = ref.watch(mediaSourcesMapProvider);
    final source = sources[article.sourceId];
    final sourceColor = source?.color ?? AppColors.primaryGreen;

    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: sourceColor.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BonoboArticleImage(
              imageUrl: article.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // Complex Gradient for cinematic look
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x60000000),
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sourceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${article.sourceName.toUpperCase()} · VEDETTE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (source?.certificationIcon != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              source!.certificationIcon,
                              size: 11,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 12, color: Colors.white60),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          DateFormatter.relative(article.publishedAt).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

// ─────────────────────────────────────────────
//  ArticleCondensedCard — Minimal List Item
// ─────────────────────────────────────────────
class ArticleCondensedCard extends ConsumerWidget {
  final FeedNews article;

  const ArticleCondensedCard({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sources = ref.watch(mediaSourcesMapProvider);
    final source = sources[article.sourceId];
    final sourceColor = source?.color ?? AppColors.primaryGreen;

    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B26) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: sourceColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            article.sourceName,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: sourceColor),
                          ),
                          if (source?.certificationIcon != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              source!.certificationIcon,
                              size: 11,
                              color: sourceColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Text('·', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.relative(article.publishedAt),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (article.imageUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BonoboArticleImage(
                  imageUrl: article.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
