import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Widget favicon d'un média.
/// Tentative 1 : URL favicon directe du site (ex. /favicon.ico)
/// Tentative 2 : Google Favicon API (plus fiable)
/// Fallback   : Avatar coloré avec initiales
class MediaFavicon extends StatelessWidget {
  final String? faviconUrl;
  final String fallbackInitials;
  final Color fallbackColor;
  final double size;
  final double borderRadius;

  const MediaFavicon({
    super.key,
    required this.faviconUrl,
    required this.fallbackInitials,
    required this.fallbackColor,
    this.size = 44,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (faviconUrl == null || faviconUrl!.isEmpty) {
      return _fallback();
    }

    return CachedNetworkImage(
      imageUrl: faviconUrl!,
      width: size,
      height: size,
      imageBuilder: (_, img) => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          color: fallbackColor.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.all(size * 0.1),
            child: Image(image: img, fit: BoxFit.contain),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(),
      placeholder: (_, __) => _shimmer(),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [fallbackColor, fallbackColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          fallbackInitials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.36,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _shimmer() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Calcule l'URL favicon à partir d'une URL de feed.
/// Utilise d'abord le /favicon.ico du domaine, puis Google Favicon API.
String computeFaviconUrl(String feedUrl) {
  try {
    final uri = Uri.parse(feedUrl);
    final domain = '${uri.scheme}://${uri.host}';
    // Google Favicon API — très fiable, taille 64x64
    return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
  } catch (_) {
    return '';
  }
}
