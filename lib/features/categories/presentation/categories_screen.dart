import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../news/presentation/widgets/article_card.dart';
import '../../news/providers/news_providers.dart';

const _categories = [
  ('Politique', Icons.account_balance_rounded, 'Politique'),
  ('Économie', Icons.trending_up_rounded, 'Économie'),
  ('Sport', Icons.sports_soccer_rounded, 'Sport'),
  ('Société', Icons.groups_rounded, 'Société'),
  ('International', Icons.language_rounded, 'International'),
  ('Culture', Icons.theater_comedy_rounded, 'Culture'),
  ('Sécurité', Icons.shield_rounded, 'Sécurité'),
  ('Santé', Icons.medical_services_rounded, 'Santé'),
];

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BonoboAppBar(title: 'Catégories'),
      body: Column(
        children: [
          const OfflineBanner(),
          // Category grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat.$3;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = isSelected ? null : cat.$3;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : isDark
                              ? const Color(0xFF1E2035)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat.$2,
                          size: 28,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.primaryGreen),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.$1,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isDark
                                    ? Colors.white70
                                    : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Articles for selected category
          Expanded(
            child: _selectedCategory == null
                ? _AllCategoriesPreview()
                : _CategoryArticles(category: _selectedCategory!),
          ),
        ],
      ),
    );
  }
}

class _AllCategoriesPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);
    return newsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (articles) => ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: articles.take(20).length,
        itemBuilder: (context, index) => ArticleCard(article: articles[index]),
      ),
    );
  }
}

class _CategoryArticles extends ConsumerWidget {
  final String category;

  const _CategoryArticles({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(newsForCategoryProvider(category));
    return articlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement')),
      data: (articles) {
        if (articles.isEmpty) {
          return Center(
            child: Text(
              'Aucun article en $category',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: articles.length,
          itemBuilder: (context, index) => ArticleCard(article: articles[index]),
        );
      },
    );
  }
}
