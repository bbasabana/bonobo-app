import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/news/domain/feed_news.dart';
import '../../../features/news/presentation/widgets/article_card.dart';

/// Modèle de données journaliste (à connecter au backend).
class JournalistProfile {
  final String id;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? role;
  final List<String> mediaExperiences; // médias où il a travaillé
  final int articlesCount;
  final int totalViews;

  const JournalistProfile({
    required this.id,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.role,
    this.mediaExperiences = const [],
    this.articlesCount = 0,
    this.totalViews = 0,
  });

  factory JournalistProfile.fromJson(Map<String, dynamic> json) {
    return JournalistProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Journaliste',
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
      mediaExperiences:
          (json['mediaExperiences'] as List?)?.cast<String>() ?? [],
      articlesCount: json['articlesPublished'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
    );
  }
}

/// Profil public d'un journaliste — bio, médias, articles publiés.
class JournalistProfileScreen extends ConsumerStatefulWidget {
  final String journalistId;

  const JournalistProfileScreen({super.key, required this.journalistId});

  @override
  ConsumerState<JournalistProfileScreen> createState() =>
      _JournalistProfileScreenState();
}

class _JournalistProfileScreenState
    extends ConsumerState<JournalistProfileScreen> {
  JournalistProfile? _profile;
  List<FeedNews> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // TODO: Appeler GET /api/v1/journalists/:id
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loading = false;
      // Mock data — remplacer par le vrai appel API
      _profile = JournalistProfile(
        id: widget.journalistId,
        displayName: 'Jean-Baptiste Likambo',
        bio:
            'Journaliste indépendant couvrant la politique et l\'économie de la RDC depuis 2015. Ancien correspondant pour Radio Okapi et Actualité.cd.',
        role: 'Journaliste politique & économique',
        mediaExperiences: ['Radio Okapi', 'Actualité.cd', 'Congo Independent'],
        articlesCount: 47,
        totalViews: 128500,
      );
      _articles = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF4F6F8),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primaryGreenStart))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)))
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(isDark),
                    SliverToBoxAdapter(child: _buildBody(isDark)),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    final profile = _profile!;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF111B13) : AppColors.backgroundDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B0F), Color(0xFF1A3A20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Motif décoratif
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreenStart.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primaryGreenStart, width: 2),
                    ),
                    child: ClipOval(
                      child: profile.avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: profile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _avatarFallback(profile),
                            )
                          : _avatarFallback(profile),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nom + role
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenStart
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'JOURNALISTE BONOBO',
                            style: GoogleFonts.inter(
                              color: AppColors.primaryGreenStart,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile.displayName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (profile.role != null)
                          Text(
                            profile.role!,
                            style: GoogleFonts.inter(
                                color: Colors.white60, fontSize: 11),
                          ),
                      ],
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

  Widget _avatarFallback(JournalistProfile profile) {
    return Container(
      color: AppColors.primaryGreenStart.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          profile.displayName.isNotEmpty
              ? profile.displayName[0].toUpperCase()
              : 'J',
          style: GoogleFonts.poppins(
              color: AppColors.primaryGreenStart,
              fontSize: 28,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final profile = _profile!;
    final card = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.white60 : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats rapides
          Row(
            children: [
              _StatChip(
                  label: 'Articles',
                  value: '${profile.articlesCount}',
                  isDark: isDark),
              const SizedBox(width: 10),
              _StatChip(
                  label: 'Lectures',
                  value: _formatViews(profile.totalViews),
                  isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Bio
          if (profile.bio != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('À propos',
                      style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(profile.bio!,
                      style: GoogleFonts.inter(
                          color: textSecondary, fontSize: 13, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Médias
          if (profile.mediaExperiences.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expériences médias',
                      style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.mediaExperiences.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreenStart
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primaryGreenStart
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(m,
                            style: GoogleFonts.inter(
                                color: AppColors.primaryGreenStart,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Articles
          if (_articles.isNotEmpty) ...[
            Text('Articles publiés',
                style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...List.generate(
                _articles.length,
                (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ArticleCard(article: _articles[i]),
                    )),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.article_outlined,
                      color: textSecondary, size: 36),
                  const SizedBox(height: 8),
                  Text('Aucun article publié pour l\'instant.',
                      style: GoogleFonts.inter(
                          color: textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatViews(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatChip(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E1C) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryGreenStart.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  color: AppColors.primaryGreenStart,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontSize: 11)),
        ],
      ),
    );
  }
}
