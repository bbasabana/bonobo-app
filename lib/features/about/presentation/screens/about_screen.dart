import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1118) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    title: 'Qui sommes-nous ?',
                    content: 'Bonobo est un agrégateur de nouvelles intelligent. Nous regroupons les médias certifiés et les sources d\'information les plus fiables dans un espace unique, épuré et sans distraction. Notre rôle est de filtrer l\'essentiel pour vous offrir une expérience de lecture fluide et sourcée.',
                    icon: Icons.hub_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  
                  _InfoCard(
                    title: 'Notre Vision',
                    content: 'Nous croyons que l\'accès à une information de qualité est un droit. Loin des algorithmes addictifs, nous privilégions la rigueur éditoriale de nos partenaires pour valoriser le travail journalistique authentique et sourcé.',
                    icon: Icons.auto_awesome_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 48),

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 20),
                    child: Text(
                      'NOUS CONTACTER',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  
                  _ContactCard(
                    title: 'Publicité & Marketing',
                    email: 'ads@bonobo.app',
                    subtitle: 'Pour vos campagnes et visibilité',
                    icon: Icons.campaign_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _ContactCard(
                    title: 'Partenariats',
                    email: 'partners@bonobo.app',
                    subtitle: 'Collaborations et intégrations média',
                    icon: Icons.handshake_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _ContactCard(
                    title: 'Support Général',
                    email: 'contact@bonobo.app',
                    subtitle: 'Questions, retours et suggestions',
                    icon: Icons.help_outline_rounded,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 60),
                  Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        '© 2026 Bonobo App · v1.0.5',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 260.0,
      floating: false,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppColors.primaryGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4ADE80), Color(0xFF01732C), Color(0xFF036027)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle patterns or decorative elements
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -40,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              // Simplified Logo presentation
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    width: 160,
                    fit: BoxFit.contain,
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.7,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String email;
  final IconData icon;
  final bool isDark;

  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.email,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchEmail(email),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B26) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.alternate_email_rounded,
              size: 18,
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }
}
