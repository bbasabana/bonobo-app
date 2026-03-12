import 'package:html/parser.dart' as html_parser;

class HtmlUtils {
  HtmlUtils._();

  // Table des entités HTML nommées fréquentes (WordPress + HTML standard)
  static const _namedEntities = {
    '&amp;':    '&',
    '&lt;':     '<',
    '&gt;':     '>',
    '&quot;':   '"',
    '&apos;':   "'",
    '&nbsp;':   ' ',
    '&ndash;':  '–',
    '&mdash;':  '—',
    '&lsquo;':  '\u2018',
    '&rsquo;':  '\u2019',
    '&ldquo;':  '\u201C',
    '&rdquo;':  '\u201D',
    '&laquo;':  '«',
    '&raquo;':  '»',
    '&hellip;': '…',
    '&eacute;': 'é',
    '&egrave;': 'è',
    '&ecirc;':  'ê',
    '&euml;':   'ë',
    '&agrave;': 'à',
    '&acirc;':  'â',
    '&auml;':   'ä',
    '&ocirc;':  'ô',
    '&ucirc;':  'û',
    '&ugrave;': 'ù',
    '&ccedil;': 'ç',
    '&iuml;':   'ï',
    '&Eacute;': 'É',
    '&Egrave;': 'È',
    '&Agrave;': 'À',
    '&Ccedil;': 'Ç',
    '&times;':  '×',
    '&divide;': '÷',
    '&euro;':   '€',
  };

  /// Décode toutes les entités HTML (numériques et nommées).
  static String decodeHtmlEntities(String text) {
    if (text.isEmpty) return text;
    // 1. Entités numériques décimales : &#039; &#8217; etc.
    String result = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );
    // 2. Entités numériques hexadécimales : &#x27; &#x2019; etc.
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    // 3. Entités nommées
    _namedEntities.forEach((entity, replacement) {
      result = result.replaceAll(entity, replacement);
    });
    return result;
  }

  /// Supprime les balises HTML et décode les entités.
  static String stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    // Utiliser le parser HTML (fiable pour les grands blocs de contenu)
    final document = html_parser.parse(htmlString);
    String text = document.body?.text ?? '';
    // Passer ensuite par le décodeur pour les entités résiduelles
    text = decodeHtmlEntities(text);
    return text.trim();
  }

  /// Nettoie un extrait : supprime HTML + entités, tronque à maxLength.
  static String cleanExcerpt(String htmlString, {int maxLength = 150}) {
    final text = stripHtml(htmlString);
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }

  static String? extractFirstImageUrl(dynamic rendered) {
    if (rendered == null) return null;
    final content = rendered.toString();
    final regex = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
    final match = regex.firstMatch(content);
    return match?.group(1);
  }
}
