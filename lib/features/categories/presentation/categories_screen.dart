import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../news/domain/feed_news.dart';
import '../../news/presentation/widgets/article_card.dart';
import '../../news/providers/news_providers.dart';

/// Catégories Explorer : (label, icône). Pas d’emoji, icônes uniquement.
const List<({String label, IconData icon})> _categories = [
  (label: 'Tout', icon: Icons.dashboard_rounded),
  (label: 'Politique', icon: Icons.account_balance_rounded),
  (label: 'Économie', icon: Icons.trending_up_rounded),
  (label: 'Sport', icon: Icons.sports_soccer_rounded),
  (label: 'Société', icon: Icons.groups_rounded),
  (label: 'International', icon: Icons.language_rounded),
  (label: 'Culture', icon: Icons.theater_comedy_rounded),
  (label: 'Sécurité', icon: Icons.shield_rounded),
  (label: 'Santé', icon: Icons.medical_services_rounded),
];

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  /// null = "Tout"
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BonoboAppBar(title: 'Explorer'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OfflineBanner(),
          _HorizontalCategoryStrip(
            isDark: isDark,
            selected: _selectedCategory,
            onSelect: (v) => setState(() => _selectedCategory = v),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          Expanded(
            child: _selectedCategory == null
                ? _AllArticlesList(isDark: isDark)
                : _CategoryArticlesList(
                    category: _selectedCategory!,
                    isDark: isDark,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Liste « Tous les articles » (quand « Tout » est sélectionné) ───────────
class _AllArticlesList extends ConsumerWidget {
  final bool isDark;

  const _AllArticlesList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);
    return newsAsync.when(
      loading: () => _LoadingPlaceholder(isDark: isDark),
      error: (_, __) => _ErrorPlaceholder(isDark: isDark),
      data: (articles) {
        if (articles.isEmpty) return _EmptyPlaceholder(isDark: isDark, message: 'Aucun article pour l\'instant.');
        return _ArticlesScroll(
          isDark: isDark,
          title: 'Tous les articles',
          count: articles.length,
          articles: articles,
        );
      },
    );
  }
}

// ─── Liste des articles par catégorie ────────────────────────────────────────
class _CategoryArticlesList extends ConsumerWidget {
  final String category;
  final bool isDark;

  const _CategoryArticlesList({
    required this.category,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(newsForCategoryProvider(category));

    return articlesAsync.when(
      loading: () => _LoadingPlaceholder(isDark: isDark),
      error: (_, __) => _ErrorPlaceholder(isDark: isDark),
      data: (articles) {
        if (articles.isEmpty) {
          return _EmptyPlaceholder(
            isDark: isDark,
            message: 'Aucun article dans cette catégorie.',
          );
        }
        return _ArticlesScroll(
          isDark: isDark,
          title: category,
          count: articles.length,
          articles: articles,
        );
      },
    );
  }
}

// ─── Bandeau horizontal des catégories (en haut, sous Explorer) ──────────────
class _HorizontalCategoryStrip extends StatelessWidget {
  final bool isDark;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _HorizontalCategoryStrip({
    required this.isDark,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111820) : Colors.white,
      ),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = (cat.label == 'Tout' && selected == null) || selected == cat.label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(cat.label == 'Tout' ? null : cat.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.3 : 0.15)
                        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 16, color: isSelected ? AppColors.primaryGreen : (isDark ? Colors.white54 : AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? (isDark ? Colors.white : AppColors.primaryGreen) : (isDark ? Colors.white70 : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Zone de scroll des articles (titre dynamique + liste dense) ─────────────
class _ArticlesScroll extends StatelessWidget {
  final bool isDark;
  final String title;
  final int count;
  final List<FeedNews> articles;

  const _ArticlesScroll({
    required this.isDark,
    required this.title,
    required this.count,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$count articles',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ArticleCard(
                article: articles[index],
                style: ArticleCardStyle.condensed,
              ),
            ),
            childCount: articles.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─── États : chargement, erreur, vide ──────────────────────────────────────
class _LoadingPlaceholder extends StatelessWidget {
  final bool isDark;

  const _LoadingPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Chargement…',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final bool isDark;

  const _ErrorPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Connexion indisponible',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final bool isDark;
  final String message;

  const _EmptyPlaceholder({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
