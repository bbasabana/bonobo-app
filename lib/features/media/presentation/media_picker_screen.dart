import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/media_sources.dart';
import '../../news/domain/media_source.dart';
import '../../../shared/local_storage.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/subscription_provider.dart';
import '../../../shared/widgets/bonobo_soft_toast.dart';

class MediaPickerScreen extends ConsumerStatefulWidget {
  const MediaPickerScreen({super.key});

  @override
  ConsumerState<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends ConsumerState<MediaPickerScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _filterCountry;
  String? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<MediaSource> get _filtered {
    var list = MediaSources.all;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((s) =>
        s.name.toLowerCase().contains(q) ||
        s.categories.any((c) => c.toLowerCase().contains(q)) ||
        s.countryLabel.toLowerCase().contains(q),
      ).toList();
    }
    if (_filterCountry != null) {
      list = list.where((s) => s.country == _filterCountry).toList();
    }
    if (_filterCategory != null) {
      list = list.where((s) => s.categories.contains(_filterCategory)).toList();
    }
    return list;
  }

  List<String> get _allCategories {
    final cats = <String>{};
    for (final s in MediaSources.all) cats.addAll(s.categories);
    return cats.toList()..sort();
  }

  bool get _isLoggedIn => ref.read(authProvider).isAuthenticated;

  void _onToggle(String sourceId, String sourceName, bool current) {
    if (!_isLoggedIn) {
      _showLoginSheet(sourceName);
      return;
    }
    ref.read(subscriptionProvider.notifier).toggle(sourceId);
    BonoboSoftToast.show(
      context,
      message: current
          ? 'Désabonné de $sourceName'
          : 'Vous suivez maintenant $sourceName',
      icon: current ? Icons.notifications_off_rounded : Icons.check_circle_rounded,
      iconColor: current ? Colors.orangeAccent : AppColors.primaryGreenStart,
    );
  }

  void _showLoginSheet(String sourceName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111820) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.primaryGreen, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suivez $sourceName et personnalisez\nvotre fil d\'actualité.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/compte');
                },
                icon: const Icon(Icons.person_rounded, size: 18),
                label: const Text('Se connecter · Gratuit',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Plus tard',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    fontSize: 13,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _query = '';
      _filterCountry = null;
      _filterCategory = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;
    final statusBarH = MediaQuery.of(context).padding.top;

    // Séparer abonnés vs non abonnés
    final followed = filtered.where((s) => subscriptions.contains(s.id)).toList();
    final others = filtered.where((s) => !subscriptions.contains(s.id)).toList();

    final bg = isDark ? const Color(0xFF0E1118) : const Color(0xFFF4F6FA);
    final surface = isDark ? const Color(0xFF161C26) : Colors.white;
    final divider = isDark ? const Color(0xFF1E2430) : const Color(0xFFEAEDF2);
    final labelColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? const Color(0xFF8A96A8) : AppColors.textSecondary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            // ── Header fixe (non scrollable)
            _buildHeader(
              context,
              isDark: isDark,
              surface: surface,
              labelColor: labelColor,
              subColor: subColor,
              divider: divider,
              statusBarH: statusBarH,
              followedCount: subscriptions.length,
              totalCount: MediaSources.all.length,
            ),

            // ── Liste scrollable
            Expanded(
              child: filtered.isEmpty
                  ? _EmptySearch(isDark: isDark, onClear: _clearAll)
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Bandeau login
                        if (!_isLoggedIn)
                          SliverToBoxAdapter(
                            child: _LoginBanner(
                              isDark: isDark,
                              onTap: () => context.push('/compte'),
                            ),
                          ),

                        // Section abonnés
                        if (followed.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Mes abonnements',
                            count: followed.length,
                            accentColor: AppColors.primaryGreen,
                            isDark: isDark,
                            action: subscriptions.isNotEmpty && _isLoggedIn
                                ? _UnsubscribeAllBtn(
                                    isDark: isDark,
                                    onTap: () {
                                      for (final id in List.from(subscriptions)) {
                                        ref.read(subscriptionProvider.notifier).unsubscribe(id);
                                      }
                                      BonoboSoftToast.show(context,
                                        message: 'Tous les abonnements supprimés',
                                        icon: Icons.notifications_off_rounded,
                                        iconColor: Colors.orangeAccent,
                                      );
                                    },
                                  )
                                : null,
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _MediaRow(
                                  source: followed[i],
                                  isSubscribed: true,
                                  isDark: isDark,
                                  surface: surface,
                                  divider: divider,
                                  labelColor: labelColor,
                                  subColor: subColor,
                                  onToggle: () => _onToggle(
                                      followed[i].id, followed[i].name, true),
                                  onTap: () =>
                                      context.push('/media/${followed[i].id}'),
                                ),
                                childCount: followed.length,
                              ),
                            ),
                          ),
                        ],

                        // Section autres médias
                        if (others.isNotEmpty) ...[
                          _SectionHeader(
                            title: followed.isEmpty
                                ? '${filtered.length} médias'
                                : 'Autres médias',
                            count: followed.isEmpty ? null : others.length,
                            accentColor: isDark
                                ? const Color(0xFF8A96A8)
                                : AppColors.textSecondary,
                            isDark: isDark,
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _MediaRow(
                                  source: others[i],
                                  isSubscribed: false,
                                  isDark: isDark,
                                  surface: surface,
                                  divider: divider,
                                  labelColor: labelColor,
                                  subColor: subColor,
                                  onToggle: () => _onToggle(
                                      others[i].id, others[i].name, false),
                                  onTap: () =>
                                      context.push('/media/${others[i].id}'),
                                ),
                                childCount: others.length,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool isDark,
    required Color surface,
    required Color labelColor,
    required Color subColor,
    required Color divider,
    required double statusBarH,
    required int followedCount,
    required int totalCount,
  }) {
    return Container(
      color: surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status bar space
          SizedBox(height: statusBarH),

          // Titre + retour
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: labelColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes médias',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.4,
                          color: labelColor,
                        ),
                      ),
                      Text(
                        '$totalCount sources · $followedCount suivi${followedCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (followedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 13, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          '$followedCount suivi${followedCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un média, pays, catégorie…',
                hintStyle: TextStyle(
                  color: subColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: subColor, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: subColor, size: 18),
                        onPressed: () =>
                            setState(() {
                              _query = '';
                              _searchController.clear();
                            }),
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF0F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filtres chips
          SizedBox(
            height: 38,
            child: _buildFilterChips(isDark, subColor),
          ),
          const SizedBox(height: 12),

          // Séparateur bas
          Container(height: 1, color: divider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, Color subColor) {
    final countries = MediaSources.all.map((s) => s.country).toSet().toList()
      ..sort();
    final categories = _allCategories.take(8).toList();
    final hasAnyFilter =
        _filterCountry != null || _filterCategory != null;

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Bouton reset si filtre actif
        if (hasAnyFilter)
          _FilterChip(
            label: 'Effacer',
            prefixIcon: Icons.close_rounded,
            selected: false,
            isDark: isDark,
            isReset: true,
            onTap: () => setState(() {
              _filterCountry = null;
              _filterCategory = null;
            }),
          ),
        // Pays
        ...countries.map((c) {
          final sel = _filterCountry == c;
          final label = c == 'CD'
              ? 'RDC'
              : c == 'BI'
                  ? 'Burundi'
                  : c;
          return _FilterChip(
            label: label,
            prefixIcon: Icons.flag_outlined,
            selected: sel,
            isDark: isDark,
            onTap: () =>
                setState(() => _filterCountry = sel ? null : c),
          );
        }),
        Container(
          width: 1,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          color: isDark ? Colors.white12 : const Color(0xFFDDE1EA),
        ),
        // Catégories
        ...categories.map((cat) {
          final sel = _filterCategory == cat;
          return _FilterChip(
            label: cat,
            selected: sel,
            isDark: isDark,
            onTap: () =>
                setState(() => _filterCategory = sel ? null : cat),
          );
        }),
      ],
    );
  }
}

// ─── Chip filtre ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final bool selected;
  final bool isDark;
  final bool isReset;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.prefixIcon,
    this.isReset = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = isReset
        ? Colors.redAccent
        : selected
            ? Colors.white
            : isDark
                ? const Color(0xFFB8BEC8)
                : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isReset
              ? Colors.redAccent.withValues(alpha: 0.1)
              : selected
                  ? AppColors.primaryGreen
                  : isDark
                      ? const Color(0xFF1C2330)
                      : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isReset
                ? Colors.redAccent.withValues(alpha: 0.3)
                : selected
                    ? AppColors.primaryGreen
                    : isDark
                        ? const Color(0xFF2A3244)
                        : const Color(0xFFDDE1EA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 12, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header de section ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color accentColor;
  final bool isDark;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.accentColor,
    required this.isDark,
    this.count,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.1,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}

// ─── Bouton tout désabonner ───────────────────────────────────────────────────
class _UnsubscribeAllBtn extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _UnsubscribeAllBtn({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.2)),
        ),
        child: const Text(
          'Tout désabonner',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Ligne média ──────────────────────────────────────────────────────────────
class _MediaRow extends StatelessWidget {
  final MediaSource source;
  final bool isSubscribed;
  final bool isDark;
  final Color surface;
  final Color divider;
  final Color labelColor;
  final Color subColor;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _MediaRow({
    required this.source,
    required this.isSubscribed,
    required this.isDark,
    required this.surface,
    required this.divider,
    required this.labelColor,
    required this.subColor,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSubscribed
              ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.07 : 0.05)
              : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSubscribed
                ? AppColors.primaryGreen.withValues(alpha: 0.25)
                : divider,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Favicon
              _FaviconBox(source: source, isDark: isDark),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            source.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                              color: labelColor,
                            ),
                          ),
                        ),
                        if (isSubscribed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded,
                                    size: 10,
                                    color: AppColors.primaryGreen),
                                SizedBox(width: 3),
                                Text(
                                  'Suivi',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        _MiniTag(
                          label: source.countryLabel,
                          icon: Icons.public_rounded,
                          isDark: isDark,
                          useSourceColor: false,
                        ),
                        ...source.categories.take(2).map((cat) => _MiniTag(
                              label: cat,
                              isDark: isDark,
                              useSourceColor: true,
                              sourceColor: source.color,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Toggle switch
              _ToggleSwitch(
                active: isSubscribed,
                onTap: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Favicon box ──────────────────────────────────────────────────────────────
class _FaviconBox extends StatelessWidget {
  final MediaSource source;
  final bool isDark;

  const _FaviconBox({required this.source, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2330) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFEAEDF2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: CachedNetworkImage(
            imageUrl: source.faviconUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => _Initials(source: source),
            errorWidget: (_, __, ___) => _Initials(source: source),
          ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final MediaSource source;
  const _Initials({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: source.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          source.initials,
          style: TextStyle(
            color: source.color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ─── Mini tag ─────────────────────────────────────────────────────────────────
class _MiniTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isDark;
  final bool useSourceColor;
  final Color? sourceColor;

  const _MiniTag({
    required this.label,
    required this.isDark,
    required this.useSourceColor,
    this.icon,
    this.sourceColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = useSourceColor
        ? (sourceColor ?? AppColors.primaryGreen)
        : isDark
            ? const Color(0xFF8A96A8)
            : AppColors.textSecondary;

    final Color bg = useSourceColor
        ? (sourceColor ?? AppColors.primaryGreen).withValues(alpha: 0.12)
        : isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF0F2F7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle switch soft ───────────────────────────────────────────────────────
class _ToggleSwitch extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _ToggleSwitch({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryGreen
              : const Color(0xFFDDE1EA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment:
              active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              active
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 12,
              color: active
                  ? AppColors.primaryGreen
                  : const Color(0xFFB8BEC8),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bandeau login ────────────────────────────────────────────────────────────
class _LoginBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _LoginBanner({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.amber.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                color: Colors.amber.shade600, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Connectez-vous pour suivre des médias et personnaliser votre fil.',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.amber.shade600),
          ],
        ),
      ),
    );
  }
}

// ─── État vide recherche ──────────────────────────────────────────────────────
class _EmptySearch extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClear;

  const _EmptySearch({required this.isDark, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: isDark ? Colors.white12 : const Color(0xFFCDD0D8),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Essayez un autre terme ou réinitialisez les filtres',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réinitialiser',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              backgroundColor:
                  AppColors.primaryGreen.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
