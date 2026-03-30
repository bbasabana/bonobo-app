import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/providers/saved_articles_provider.dart';
import '../../../../shared/widgets/bonobo_app_bar.dart';
import '../../../../shared/widgets/bonobo_article_image.dart';
import '../../domain/feed_news.dart';
import '../../providers/news_providers.dart';

class SavedArticlesScreen extends ConsumerWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state string list for rebuilds
    ref.watch(savedArticlesProvider);
    // Get full objects for the list
    final savedArticles = ref.read(savedArticlesProvider.notifier).savedArticles;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1118) : const Color(0xFFF8FAFC),
      appBar: const BonoboAppBar(title: 'Ma Bibliothèque'),
      body: savedArticles.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: savedArticles.length,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final article = savedArticles[index];
                return _SavedArticleCard(article: article);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_add_outlined,
                size: 54,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Votre bibliothèque est vide',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Enregistrez vos articles préférés pour les lire plus tard, même sans connexion.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Explorer le flux',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedArticleCard extends ConsumerWidget {
  final FeedNews article;

  const _SavedArticleCard({required this.article});

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
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image vignette
              SizedBox(
                width: 110,
                child: BonoboArticleImage(
                  imageUrl: article.imageUrl,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sourceColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.sourceName.toUpperCase(),
                              style: TextStyle(
                                color: sourceColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.bookmark_remove_rounded, size: 20),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: isDark ? Colors.white30 : Colors.black26,
                            onPressed: () {
                              ref.read(savedArticlesProvider.notifier).toggle(article);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Article retiré de la bibliothèque'),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'ANNULER',
                                    textColor: AppColors.primaryGreenStart,
                                    onPressed: () => ref.read(savedArticlesProvider.notifier).toggle(article),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.3,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isDark ? Colors.white38 : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.relative(article.publishedAt),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
