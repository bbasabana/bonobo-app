/// Utilitaires pour améliorer la qualité d'affichage des images (agrégateur multi-sources).
library;

/// Retourne une URL d'image en meilleure résolution quand la source le permet.
/// WordPress : ?w=400 → ?w=1200 ; paramètres _wp_attached_file, etc.
String imageUrlHighRes(String url, {int preferredWidth = 1200}) {
  if (url.isEmpty) return url;
  try {
    final uri = Uri.parse(url);
    final query = Map<String, String>.from(uri.queryParameters);

    // WordPress : w, h, resize
    if (query.containsKey('w') && uri.host.contains('wordpress')) {
      query['w'] = preferredWidth.toString();
      return uri.replace(queryParameters: query).toString();
    }
    if (query.containsKey('width')) {
      query['width'] = preferredWidth.toString();
      return uri.replace(queryParameters: query).toString();
    }

    // Ajouter ?w= pour les URLs WordPress sans paramètre
    if (uri.host.contains('wordpress') || uri.path.contains('wp-content')) {
      final sep = uri.query.isEmpty ? '?' : '&';
      return '$url${sep}w=$preferredWidth';
    }

    return url;
  } catch (_) {
    return url;
  }
}

/// Largeur de cache recommandée pour un affichage net (2x device pixel ratio).
int cacheWidthForDisplay(double displayWidth, double devicePixelRatio) {
  final target = (displayWidth * devicePixelRatio).round();
  return target.clamp(400, 1600);
}

int cacheHeightForDisplay(double displayHeight, double devicePixelRatio) {
  final target = (displayHeight * devicePixelRatio).round();
  return target.clamp(300, 1200);
}
