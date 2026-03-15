import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/news_providers.dart';
import '../../providers/news_providers.dart';
import '../widgets/article_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (mounted) ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final sourceId = ref.watch(searchSourceIdProvider);
    final category = ref.watch(searchCategoryProvider);
    final dateRange = ref.watch(searchDateRangeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1118),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Rechercher dans tous les médias…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            border: InputBorder.none,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.white.withValues(alpha: 0.7)),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FiltersBar(
            sourceId: sourceId,
            category: category,
            dateRange: dateRange,
            onSourceChanged: (v) => ref.read(searchSourceIdProvider.notifier).state = v,
            onCategoryChanged: (v) => ref.read(searchCategoryProvider.notifier).state = v,
            onDateRangeChanged: (v) => ref.read(searchDateRangeProvider.notifier).state = v,
          ),
          Expanded(
            child: results.isEmpty
                ? _EmptyState(hasQuery: query.isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final article = results[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ArticleListCard(article: article),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends ConsumerWidget {
  final String? sourceId;
  final String? category;
  final String? dateRange;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onDateRangeChanged;

  const _FiltersBar({
    required this.sourceId,
    required this.category,
    required this.dateRange,
    required this.onSourceChanged,
    required this.onCategoryChanged,
    required this.onDateRangeChanged,
  });

  static const _categories = [
    'Politique',
    'Économie',
    'Sport',
    'Société',
    'International',
    'Culture',
    'Sécurité',
    'Santé',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesMap = ref.watch(mediaSourcesMapProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.backgroundDark.withValues(alpha: 0.6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Source',
              value: sourceId == null ? null : sourcesMap[sourceId]?.name,
              onClear: () => onSourceChanged(null),
              onTap: () => _showSourcePicker(context, ref),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Catégorie',
              value: category,
              onClear: category == null ? null : () => onCategoryChanged(null),
              onTap: () => _showCategoryPicker(context),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Période',
              value: dateRange == null ? null : (dateRange == '24h' ? '24 h' : dateRange == '7j' ? '7 jours' : '30 jours'),
              onClear: dateRange == null ? null : () => onDateRangeChanged(null),
              onTap: () => _showDatePicker(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourcePicker(BuildContext context, WidgetRef ref) {
    final list = ref.watch(dynamicMediaSourcesProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Choisir un média', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ...list.map((s) => ListTile(
                  title: Text(s.name, style: const TextStyle(color: Colors.white)),
                  selected: sourceId == s.id,
                  onTap: () {
                    onSourceChanged(s.id);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Catégorie', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ..._categories.map((c) => ListTile(
                  title: Text(c, style: const TextStyle(color: Colors.white)),
                  selected: category == c,
                  onTap: () {
                    onCategoryChanged(c);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Période', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              title: const Text('24 heures', style: TextStyle(color: Colors.white)),
              selected: dateRange == '24h',
              onTap: () {
                onDateRangeChanged('24h');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('7 jours', style: TextStyle(color: Colors.white)),
              selected: dateRange == '7j',
              onTap: () {
                onDateRangeChanged('7j');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('30 jours', style: TextStyle(color: Colors.white)),
              selected: dateRange == '30j',
              onTap: () {
                onDateRangeChanged('30j');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onClear;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    this.onClear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null ? AppColors.primaryGreen.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null ? AppColors.primaryGreenStart : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                color: value != null ? AppColors.primaryGreenStart : Colors.white70,
                fontSize: 13,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (value != null && onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;

  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.article_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery
                  ? 'Aucun article ne correspond à votre recherche.\nEssayez d\'autres mots ou filtres.'
                  : 'Recherchez dans tous les médias agrégés par Bonobo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
