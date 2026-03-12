import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Emplacement réservé pour la publicité à vendre.
/// Respecte la charte graphique ; à remplacer par un vrai bloc pub (AdMob, custom, etc.).
class AdPlaceholder extends StatelessWidget {
  /// Hauteur du bandeau (ex. 50 pour banner, 250 pour rectangle).
  final double height;
  /// Label affiché en mode placeholder (ex. "Espace publicitaire").
  final String label;

  const AdPlaceholder({
    super.key,
    this.height = 56,
    this.label = 'Espace publicitaire',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2035) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.2)
              : AppColors.primaryGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 18,
              color: AppColors.primaryGreen.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryGreen.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
