import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../domain/job_offer.dart';
import '../providers/jobs_providers.dart';

// ─── Couleur source badge ──────────────────────────────────────────────────────
Color _sourceColor(String source) {
  switch (source) {
    case 'careerjet':
      return const Color(0xFF1565C0);
    default:
      return AppColors.primaryGreen;
  }
}

String _sourceLabel(String source) {
  switch (source) {
    case 'careerjet':
      return 'Careerjet';
    default:
      return 'Mediacongo';
  }
}

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  static List<JobOffer> _filter(List<JobOffer> jobs, String q) {
    if (q.trim().isEmpty) return jobs;
    final lower = q.trim().toLowerCase();
    return jobs.where((j) {
      return j.title.toLowerCase().contains(lower) ||
          j.employer.toLowerCase().contains(lower) ||
          (j.location?.toLowerCase().contains(lower) ?? false) ||
          j.description.toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1118) : const Color(0xFFF2F4F7),
      appBar: const BonoboAppBar(title: 'Offres d\'emploi'),
      body: Column(
        children: [
          const OfflineBanner(),
          // Bandeau header emploi
          _JobsHeader(isDark: isDark),
          // Barre de recherche
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _isSearchOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: _SearchBar(
              isDark: isDark,
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _searchQuery = v),
              onClose: () {
                setState(() {
                  _isSearchOpen = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            secondChild: const SizedBox.shrink(),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          // Contenu principal
          Expanded(
            child: jobsAsync.when(
              loading: () => _LoadingState(isDark: isDark),
              error: (_, __) => _ErrorState(isDark: isDark),
              data: (jobs) {
                final filtered = _filter(jobs, _searchQuery);
                if (filtered.isEmpty) {
                  return _EmptyState(
                    isDark: isDark,
                    isSearch: _searchQuery.isNotEmpty,
                    query: _searchQuery,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(refreshJobsProvider)(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 4, height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _searchQuery.isNotEmpty ? 'Résultats' : 'Offres en RDC',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
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
                                  '${filtered.length} offres',
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
                          (ctx, i) => _JobCard(
                            job: filtered[i],
                            isDark: isDark,
                            onTap: () => _showDetail(ctx, filtered[i], isDark),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSearchOpen
          ? null
          : Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    setState(() => _isSearchOpen = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _searchFocus.requestFocus();
                    });
                  },
                  child: const Center(
                    child: Icon(Icons.search_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
    );
  }

  void _showDetail(BuildContext context, JobOffer job, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1D2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _JobDetailSheet(job: job, isDark: isDark),
    );
  }
}

// ─── Header bannière emploi ────────────────────────────────────────────────────
class _JobsHeader extends StatelessWidget {
  final bool isDark;

  const _JobsHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF01732C), Color(0xFF025A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emplois RDC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mediacongo.net · Careerjet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barre de recherche ────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar({
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF161D2A) : Colors.white,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Fonction, entreprise, lieu…',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryGreen, size: 22),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Carte offre d'emploi ──────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final JobOffer job;
  final bool isDark;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final src = job.source;
    final badgeColor = _sourceColor(src);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_outline_rounded, color: AppColors.primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.3,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.employer,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _sourceLabel(src),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (job.description.isNotEmpty)
                Text(
                  job.description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (job.location != null && job.location!.isNotEmpty) ...[
                    Icon(Icons.place_rounded, size: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        job.location!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (job.salary != null && job.salary!.isNotEmpty) ...[
                    Icon(Icons.attach_money_rounded, size: 12, color: AppColors.primaryGreenStart),
                    const SizedBox(width: 4),
                    Text(
                      job.salary!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreenStart,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  Text(
                    'Voir l\'offre',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primaryGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fiche détail (bottom sheet) ──────────────────────────────────────────────
class _JobDetailSheet extends StatelessWidget {
  final JobOffer job;
  final bool isDark;

  const _JobDetailSheet({required this.job, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final badgeColor = _sourceColor(job.source);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Source badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _sourceLabel(job.source).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (job.deadline != null && job.deadline!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              job.deadline!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Titre
                  Text(
                    job.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      height: 1.3,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Employeur
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business_rounded, color: AppColors.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          job.employer,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Détails
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (job.location != null && job.location!.isNotEmpty)
                        _InfoChip(icon: Icons.place_rounded, label: job.location!, isDark: isDark),
                      if (job.reference != null && job.reference!.isNotEmpty)
                        _InfoChip(icon: Icons.tag_rounded, label: job.reference!, isDark: isDark),
                      if (job.salary != null && job.salary!.isNotEmpty)
                        _InfoChip(
                          icon: Icons.attach_money_rounded,
                          label: job.salary!,
                          isDark: isDark,
                          color: AppColors.primaryGreenStart,
                        ),
                      if (job.contractType != null && job.contractType!.isNotEmpty)
                        _InfoChip(icon: Icons.badge_rounded, label: job.contractType!, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: isDark ? Colors.white12 : Colors.grey.shade100),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    job.description.isNotEmpty
                        ? job.description
                        : 'Voir l\'offre complète sur le site du recruteur.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Bouton postuler
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(job.sourceUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: const Text(
                        'Postuler / Voir l\'offre complète',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? Colors.white54 : AppColors.textSecondary);
    final bg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null ? color!.withValues(alpha: 0.1) : bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

// ─── États ────────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  final bool isDark;
  const _LoadingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Chargement des offres…',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isDark;
  const _ErrorState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(height: 12),
          Text('Connexion indisponible',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool isSearch;
  final String query;
  const _EmptyState({required this.isDark, required this.isSearch, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.work_off_rounded,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              isSearch ? 'Aucun résultat pour « $query »' : 'Aucune offre disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            if (isSearch)
              Text(
                'Essayez d\'autres mots-clés.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
