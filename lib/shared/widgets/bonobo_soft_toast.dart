import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/connectivity_service.dart';

/// Toast soft conforme à la charte Bonobo : fond sombre, bords arrondis,
/// couleurs primary green. Utilisé pour connectivité, cache, notifications.
class BonoboSoftToast {
  static const double _horizontalMargin = 20;
  static const double _bottomMargin = 24;
  static const double _radius = 14;
  static const int _durationSeconds = 3;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryGreenStart)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primaryGreenStart,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(_horizontalMargin, 0, _horizontalMargin, _bottomMargin),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        duration: const Duration(seconds: _durationSeconds),
      ),
    );
  }

  /// Toast quand connexion perdue (design soft).
  static void showOffline(BuildContext context) {
    show(
      context,
      message: 'Connexion perdue. Affichage des articles enregistrés.',
      icon: Icons.cloud_off_rounded,
      iconColor: Colors.orangeAccent,
    );
  }

  /// Toast quand reconnexion (design soft).
  static void showBackOnline(BuildContext context) {
    show(
      context,
      message: 'Vous êtes de nouveau connecté. Actualités à jour.',
      icon: Icons.wifi_rounded,
      iconColor: AppColors.primaryGreenStart,
    );
  }

  /// Toast quand les articles sont sauvegardés en local.
  static void showArticlesSavedLocally(BuildContext context) {
    show(
      context,
      message: 'Articles enregistrés pour consultation hors ligne.',
      icon: Icons.save_rounded,
      iconColor: AppColors.primaryGreenStart,
    );
  }

  /// Toast intelligent affichant la qualité de la connexion.
  static void showConnectionQuality(BuildContext context, ConnectionQuality quality, String type) {
    switch (quality) {
      case ConnectionQuality.good:
        show(context,
          message: 'Connexion $type excellente. Chargement rapide.',
          icon: Icons.signal_wifi_4_bar_rounded,
          iconColor: AppColors.primaryGreenStart,
        );
        break;
      case ConnectionQuality.moderate:
        show(context,
          message: 'Connexion $type correcte. Le chargement peut prendre un moment.',
          icon: Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
          iconColor: Colors.amber,
        );
        break;
      case ConnectionQuality.poor:
        show(context,
          message: 'Connexion $type instable. Qualité faible, veuillez patienter.',
          icon: Icons.signal_wifi_bad_rounded,
          iconColor: Colors.orangeAccent,
        );
        break;
      case ConnectionQuality.none:
        show(context,
          message: 'Aucune connexion détectée. Vérifiez votre réseau.',
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.redAccent,
        );
        break;
    }
  }
}
