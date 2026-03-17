import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/bonobo_app_bar.dart';

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
          SliverToBoxAdapter(
            child: _AboutHero(isDark: isDark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    title: 'Qui sommes-nous ?',
                    icon: Icons.hub_rounded,
                    color: AppColors.primaryGreenStart,
                  ),
                  const SizedBox(height: 16),
                  const _SectionText(
                    text: 'Bonobo est un agrégateur de nouvelles intelligent. Nous regroupons les médias certifiés et les sources d\'information les plus fiables dans un espace unique, épuré et sans distraction. Notre rôle est de filtrer l\'essentiel pour vous offrir une expérience de lecture fluide et sourcée.',
                  ),
                  const SizedBox(height: 40),
                  
                  _SectionTitle(
                    title: 'Notre Vision',
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  const _SectionText(
                    text: 'Nous croyons que l\'accès à une information de qualité est un droit. Loin des algorithmes addictifs, nous privilégions la rigueur éditoriale de nos partenaires pour valoriser le travail journalistique authentique et sourcé.',
                  ),
                  const SizedBox(height: 40),

                  _SectionTitle(
                    title: 'Nous Contacter',
                    icon: Icons.alternate_email_rounded,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 20),
                  
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
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
}

class _AboutHero extends StatelessWidget {
  final bool isDark;
  const _AboutHero({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF0E1118), const Color(0xFF0E1118)]
            : [const Color(0xFFF8FAFC), const Color(0xFFF8FAFC)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Spacer(),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
        fontWeight: FontWeight.w400,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryGreenStart, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryGreenStart,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black12,
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
