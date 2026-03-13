import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/job_offer.dart';

const _baseUrl = 'https://www.mediacongo.net';
const _emploisUrl = '$_baseUrl/emplois.html';

/// Récupère les offres d'emploi par scraping de la page mediacongo.net/emplois.html.
/// Pas de flux RSS disponible côté site.
class MediacongoJobsService {
  final Dio _dio;

  MediacongoJobsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              followRedirects: true,
              headers: {
                'Accept': 'text/html,application/xhtml+xml',
                'User-Agent': 'Bonobo/1.0 (RDC News Aggregator)',
              },
            ));

  Future<List<JobOffer>> fetchJobs() async {
    try {
      final response = await _dio.get<String>(_emploisUrl);
      final html = response.data ?? '';
      return _parseTable(html);
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  List<JobOffer> _parseTable(String html) {
    final doc = parse(html);
    final table = doc.querySelector('table.table_datas');
    if (table == null) return [];

    final rows = table.querySelectorAll('tr');
    final results = <JobOffer>[];
    final now = DateTime.now();

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final cells = row.querySelectorAll('td');
      if (cells.length < 5) continue;

      final job = _parseRow(cells, now);
      if (job != null) results.add(job);
    }

    return results;
  }

  JobOffer? _parseRow(List<Element> cells, DateTime fetchedAt) {
    // Column 0: link to detail
    // Column 1: title + reference (strong + strong.format_id_emploi)
    // Column 2: organisme (td.grey)
    // Column 3: lieu
    // Column 4: date (publiée)

    String? detailPath;
    String title = '';
    String? reference;
    String employer = '';
    String location = '';
    String? publishedDate;

    final linkInCol0 = cells[0].querySelector('a');
    if (linkInCol0 != null) {
      final href = linkInCol0.attributes['href'];
      if (href != null && href.isNotEmpty) detailPath = _resolveUrl(href);
    }

    if (cells.length > 1) {
      final linkInCol1 = cells[1].querySelector('a');
      if (linkInCol1 != null) {
        if (detailPath == null) {
          final href = linkInCol1.attributes['href'];
          if (href != null && href.isNotEmpty) detailPath = _resolveUrl(href);
        }
        final strongs = linkInCol1.querySelectorAll('strong');
        for (final s in strongs) {
          if (s.classes.contains('format_id_emploi')) {
            reference = s.text.trim();
          } else {
            final t = s.text.trim();
            if (t.isNotEmpty) title = t;
          }
        }
        if (title.isEmpty) title = linkInCol1.text.trim().replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }

    if (cells.length > 2) {
      final orgLink = cells[2].querySelector('a');
      if (orgLink != null) employer = orgLink.text.trim();
    }
    if (cells.length > 3) {
      final lieuLink = cells[3].querySelector('a');
      if (lieuLink != null) location = lieuLink.text.trim();
    }
    if (cells.length > 4) {
      final dateLink = cells[4].querySelector('a');
      if (dateLink != null) publishedDate = dateLink.text.trim();
    }

    if (title.isEmpty) return null;

    final sourceUrl = detailPath ?? _emploisUrl;
    final id = reference ?? _extractIdFromUrl(sourceUrl) ?? 'mc_${sourceUrl.hashCode}_${title.hashCode}';
    final description = [
      if (reference != null) 'Réf. $reference',
      if (location.isNotEmpty) location,
      if (publishedDate != null) 'Publiée le $publishedDate',
    ].join(' · ');

    return JobOffer(
      id: id,
      title: title,
      employer: employer.isNotEmpty ? employer : 'Mediacongo',
      description: description.isNotEmpty ? description : 'Voir l\'offre sur mediacongo.net',
      deadline: publishedDate,
      sourceUrl: sourceUrl,
      fetchedAt: fetchedAt,
      location: location.isNotEmpty ? location : null,
      reference: reference,
    );
  }

  /// Ex: emploi-societe-43236_xxx.html -> OEM43236 or 43236
  String? _extractIdFromUrl(String url) {
    final match = RegExp(r'emploi-societe-(\d+)_').firstMatch(url);
    return match != null ? 'OEM${match.group(1)}' : null;
  }

  String _resolveUrl(String href) {
    href = href.trim();
    if (href.startsWith('http://') || href.startsWith('https://')) return href;
    if (href.startsWith('//')) return 'https:$href';
    if (href.startsWith('/')) return '$_baseUrl$href';
    return '$_baseUrl/$href';
  }
}
