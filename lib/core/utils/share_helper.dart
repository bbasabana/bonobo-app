/// Helper de partage Bonobo.
/// Signature inspirée "Envoyé depuis iPhone" — Option 1 + 3 fusionnées.
class BonoboShareHelper {

  /// Lien Play Store (remplacez par le vrai lien une fois l'app publiée).
  /// Format court recommandé : bit.ly/bonobo-app
  static const _playStoreLink = 'https://bit.ly/bonobo-app';

  // ── Génère le texte de partage complet ─────────────────────────────────────
  static String buildShareText({
    required String title,
    required String url,
    String? excerpt,
    String? sourceName,
  }) {
    final parts = <String>[];

    // 1. Titre de l'article
    parts.add(title);

    // 2. Extrait bref (≤ 120 caractères)
    if (excerpt != null && excerpt.isNotEmpty) {
      final brief = excerpt.length > 120
          ? '${excerpt.substring(0, 120).trimRight()}...'
          : excerpt;
      parts.add(brief);
    }

    // 3. Source
    if (sourceName != null && sourceName.isNotEmpty) {
      parts.add('Source : $sourceName');
    }

    // 4. Lien original
    parts.add('Lire la suite : $url');

    // 5. Signature fusionnée (Option 1 + 3)
    parts.add(_signature());

    return parts.join('\n\n');
  }

  /// Texte pour le sujet email / titre de notification.
  static String buildSubject(String title) => title;

  /// Texte joint à l'export PDF.
  static String buildPdfShareText(String title) =>
      '$title\n\n${_signatureShort()}';

  // ── Signature fusionnée Option 1 + 3 ──────────────────────────────────────
  // Structure :
  //   — Envoyé depuis Bonobo          ← sobre (Option 1)
  //   L'agrégateur d'actualités congolaises
  //   Kinshasa · Goma · Lubumbashi · Diaspora
  //   Téléchargez l'app : bit.ly/bonobo-app   ← lien court Play Store

  static String _signature() =>
      '——————————————\n'
      '— Envoyé depuis Bonobo\n'
      'L\'agrégateur d\'actualités congolaises\n'
      'Toutes les sources dans une seule app\n'
      'Téléchargez l\'app : $_playStoreLink';

  static String _signatureShort() =>
      '— Envoyé depuis Bonobo · L\'agrégateur d\'actualités congolaises\n'
      '$_playStoreLink';
}
