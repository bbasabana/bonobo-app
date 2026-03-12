import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_quality.dart';

/// Image d'article en haute qualité (prise en compte devicePixelRatio + URLs optimisées).
/// Placeholder Bonobo (bonobo_load_bg.jpg) pour chargement / erreur.
class BonoboArticleImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  /// Si true, demande une URL haute résolution (ex. 1200px) quand la source le permet.
  final bool highQuality;

  const BonoboArticleImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.highQuality = true,
  });

  static const String _placeholderAsset = 'assets/images/bonobo_load_bg.jpg';

  String? _resolvedUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return highQuality ? imageUrlHighRes(url, preferredWidth: 1200) : url;
  }

  bool get _hasFiniteHeight => height.isFinite && height > 0;
  bool get _hasFiniteWidth => width.isFinite && width > 0;

  Widget _withOptionalSize(Widget child) {
    // Important: `width: double.infinity` est valide pour Flutter, mais n'est pas
    // "finite". On impose donc au minimum la hauteur si elle est connue pour
    // éviter les contraintes infinies dans Stack/Clip pendant le layout.
    final sized = SizedBox(
      width: _hasFiniteWidth ? width : null,
      height: _hasFiniteHeight ? height : null,
      child: child,
    );
    return sized;
  }

  Widget _placeholder({bool loading = false}) {
    final inner = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _placeholderAsset,
            width: _hasFiniteWidth ? width : null,
            height: _hasFiniteHeight ? height : null,
            fit: fit,
            errorBuilder: (_, __, ___) => _fallbackBox(),
          ),
          if (loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreenStart),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return _withOptionalSize(inner);
  }

  Widget _fallbackBox() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.article_rounded, size: 28, color: Colors.white38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl(imageUrl);
    if (url == null || url.isEmpty) {
      return _placeholder(loading: false);
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = width.isFinite && width > 0
        ? cacheWidthForDisplay(width, dpr)
        : null;
    final cacheH = height.isFinite && height > 0
        ? cacheHeightForDisplay(height, dpr)
        : null;

    final inner = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url,
        width: _hasFiniteWidth ? width : null,
        height: _hasFiniteHeight ? height : null,
        fit: fit,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        placeholder: (_, __) => _placeholder(loading: true),
        errorWidget: (_, __, ___) => _placeholder(loading: false),
      ),
    );
    return _withOptionalSize(inner);
  }
}
