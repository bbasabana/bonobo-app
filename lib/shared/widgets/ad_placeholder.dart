import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/ads/providers/ad_provider.dart';
import '../../features/ads/domain/ad_model.dart';
import '../../core/constants/app_colors.dart';

/// Emplacement publicitaire dynamique.
/// Affiche une publicité depuis le backend si disponible, sinon un placeholder propre.
class BonoboAdWidget extends ConsumerWidget {
  /// Position de la publicité (ex: 'home_top', 'home_middle', 'article_details', 'media_details').
  final String position;
  /// Hauteur du bandeau (ex. 50 pour banner, 250 pour rectangle).
  final double height;
  /// Label affiché en mode placeholder (ex. "Espace publicitaire").
  final String label;

  const BonoboAdWidget({
    super.key,
    this.height = 56,
    this.label = 'Espace publicitaire',
    this.position = 'home_middle',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(adsProvider(position));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) return _buildPlaceholder(isDark);
        
        // Pick one randomly or the first one
        final ad = ads.first;
        
        // Track view
        Future.microtask(() => ref.read(adServiceProvider).trackEvent(ad.id, 'view'));

        return _buildAdContent(context, ref, ad, isDark);
      },
      loading: () => _buildPlaceholder(isDark),
      error: (_, __) => _buildPlaceholder(isDark),
    );
  }

  Widget _buildAdContent(BuildContext context, WidgetRef ref, AdModel ad, bool isDark) {
    return GestureDetector(
      onTap: () async {
        if (ad.redirectUrl != null) {
          final url = Uri.parse(ad.redirectUrl!);
          if (await canLaunchUrl(url)) {
            // Track click
            ref.read(adServiceProvider).trackEvent(ad.id, 'click');
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.network(
              ad.imageUrl,
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
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
