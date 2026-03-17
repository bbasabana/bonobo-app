import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../domain/sports_match.dart';
import '../providers/sports_providers.dart';

class SportsScreen extends ConsumerWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sportsAsync = ref.watch(sportsDataProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1118) : const Color(0xFFF2F4F7),
      appBar: const BonoboAppBar(title: 'Sport'),
      body: RefreshIndicator(
        onRefresh: () => ref.read(refreshSportsProvider)(),
        color: AppColors.primaryGreen,
        child: sportsAsync.when(
          loading: () => const _LoadingState(),
          error: (err, stack) => _ErrorState(onRetry: () => ref.refresh(sportsDataProvider)),
          data: (data) => CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              const SliverToBoxAdapter(child: OfflineBanner()),
              
              // --- Championnats / Filtres ---
              SliverToBoxAdapter(
                child: _LeaguesSection(leagues: data.leagues, isDark: isDark),
              ),

              // --- Matchs en Direct (Section "WOW") ---
              if (data.liveMatches.isNotEmpty)
                SliverToBoxAdapter(
                  child: _LiveMatchesSection(matches: data.liveMatches, isDark: isDark),
                ),

              // --- Prochains Matchs ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Prochains matches',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _UpcomingMatchCard(
                      match: data.upcomingMatches[index],
                      isDark: isDark,
                    ),
                    childCount: data.upcomingMatches.length,
                  ),
                ),
              ),

              // --- Actualités Sportives (Section Dynamique) ---
              if (data.news.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4, height: 18,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'À la une du sport',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _SportsNewsCard(
                        article: data.news[index],
                        isDark: isDark,
                      ),
                      childCount: data.news.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Championnats ──────────────────────────────────────────────────────
class _LeaguesSection extends StatelessWidget {
  final List<LeagueInfo> leagues;
  final bool isDark;

  const _LeaguesSection({required this.leagues, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          final league = leagues[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                    child: league.logo.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.network(league.logo),
                        )
                      : const Icon(Icons.sports_soccer_rounded, color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 6),
                Text(
                  league.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Section Direct (Carousel horizontal) ─────────────────────────────────────
class _LiveMatchesSection extends StatefulWidget {
  final List<SportsMatch> matches;
  final bool isDark;

  const _LiveMatchesSection({required this.matches, required this.isDark});

  @override
  State<_LiveMatchesSection> createState() => _LiveMatchesSectionState();
}

class _LiveMatchesSectionState extends State<_LiveMatchesSection> with SingleTickerProviderStateMixin {
  late AnimationController _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              FadeTransition(
                opacity: _blinkAnim,
                child: const Icon(Icons.sensors_rounded, color: Colors.redAccent, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'EN DIRECT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.1,
                  color: Colors.redAccent.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              _LiveBadgeCount(count: widget.matches.length),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.matches.length,
            itemBuilder: (context, index) => _LiveScoreCard(match: widget.matches[index], isDark: widget.isDark),
          ),
        ),
      ],
    );
  }
}

class _LiveBadgeCount extends StatelessWidget {
  final int count;
  const _LiveBadgeCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count matches',
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LiveScoreCard extends StatelessWidget {
  final SportsMatch match;
  final bool isDark;

  const _LiveScoreCard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      margin: const EdgeInsets.only(right: 14, bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E2235), const Color(0xFF111422)]
            : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            match.competition,
            style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TeamInfo(name: match.teamA, logo: match.logoA, isAlignRight: true),
              _ScoreDisplay(scoreA: match.scoreA, scoreB: match.scoreB, time: match.time),
              _TeamInfo(name: match.teamB, logo: match.logoB, isAlignRight: false),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Voir les statistiques',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final String name;
  final String? logo;
  final bool isAlignRight;

  const _TeamInfo({required this.name, this.logo, required this.isAlignRight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: logo != null 
              ? Image.network(logo!, errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.white))
              : const Icon(Icons.shield_rounded, color: Colors.white24, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final dynamic scoreA;
  final dynamic scoreB;
  final String time;

  const _ScoreDisplay({this.scoreA, this.scoreB, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${scoreA ?? 0} - ${scoreB ?? 0}',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ─── Prochains Matchs (Liste élégante) ────────────────────────────────────────
class _UpcomingMatchCard extends ConsumerWidget {
  final SportsMatch match;
  final bool isDark;

  const _UpcomingMatchCard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertService = ref.watch(matchAlertServiceProvider);
    final isAlerted = alertService.isAlertEnabled(match.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              match.teamA,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            children: [
              Text(
                match.time,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 2),
              Text(
                match.date ?? 'Aujourd\'hui',
                style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              match.teamB,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => alertService.toggleAlert(match),
            child: Icon(
              isAlerted ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              size: 20,
              color: isAlerted ? AppColors.primaryGreen : (isDark ? Colors.white24 : Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportsNewsCard extends StatelessWidget {
  final SportsArticle article;
  final bool isDark;

  const _SportsNewsCard({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(article.url);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.withValues(alpha: 0.1),
                    child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.sourceName.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (article.publishedAt != null)
                        Text(
                          _formatDate(article.publishedAt!),
                          style: TextStyle(
                            color: isDark ? Colors.white38 : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes}m";
      if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
      return "${date.day}/${date.month}";
    } catch (_) {
      return "";
    }
  }
}

// ─── États ────────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryGreen),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('Impossible de charger les données sportives'),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
