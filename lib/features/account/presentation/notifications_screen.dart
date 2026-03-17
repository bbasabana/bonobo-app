import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BonoboAppBar(title: 'Notifications'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pas de nouvelles notifications',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vous recevrez ici des alertes sur les derniers articles importants et les mises à jour de l\'application.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              _NotificationPreferenceTile(
                title: 'Articles importants',
                subtitle: 'Recevoir les actualités brûlantes',
                value: true,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _NotificationPreferenceTile(
                title: 'Mises à jour',
                subtitle: 'Nouveautés de l\'application',
                value: true,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPreferenceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;

  const _NotificationPreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {},
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}
