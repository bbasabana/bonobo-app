import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/job_offer.dart';

const _careerjetApiKey = '132fc42281fc396f750508e83324fb3b';
const _endpoint = 'https://search.api.careerjet.net/v4/query';

/// Récupère les offres d'emploi RDC via l'API Careerjet.
class CareerjetJobsService {
  final Dio _dio;

  CareerjetJobsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  /// Credentials Basic Auth : key:""  → base64
  String get _basicAuth {
    final creds = '$_careerjetApiKey:';
    return 'Basic ${base64Encode(utf8.encode(creds))}';
  }

  Future<List<JobOffer>> fetchJobs({
    String keywords = '',
    String location = 'RD Congo',
    int pageSize = 50,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {
          'locale_code': 'fr_CD',
          'keywords': keywords.isNotEmpty ? keywords : 'emploi',
          'location': location,
          'sort': 'date',
          'page_size': pageSize,
          'page': page,
          'fragment_size': 200,
          'user_ip': '127.0.0.1',
          'user_agent': 'Bonobo/1.0 Android Flutter',
        },
        options: Options(
          headers: {'Authorization': _basicAuth},
        ),
      );

      final data = response.data;
      if (data == null || data['type'] != 'JOBS') return [];

      final jobs = data['jobs'] as List<dynamic>? ?? [];
      final now = DateTime.now();

      return jobs.map((j) {
        final job = j as Map<String, dynamic>;
        final title = (job['title'] as String? ?? '').trim();
        final company = (job['company'] as String? ?? '').trim();
        final desc = (job['description'] as String? ?? '').trim();
        final locs = (job['locations'] as String? ?? '').trim();
        final url = (job['url'] as String? ?? '').trim();
        final salaryRaw = job['salary'] as String?;
        final salaryCurrency = job['salary_currency_code'] as String?;
        final date = job['date'] as String?;
        final site = (job['site'] as String? ?? '').trim();

        DateTime? publishedAt;
        if (date != null && date.isNotEmpty) {
          publishedAt = DateTime.tryParse(date);
        }

        final id = 'cj_${url.hashCode}_${title.hashCode}';

        return JobOffer(
          id: id,
          title: title.isNotEmpty ? title : 'Offre sans titre',
          employer: company.isNotEmpty ? company : site.isNotEmpty ? site : 'Recruteur',
          description: desc.isNotEmpty ? desc : 'Voir l\'offre complète sur le site du recruteur.',
          deadline: date,
          sourceUrl: url.isNotEmpty ? url : 'https://www.careerjet.cd',
          fetchedAt: now,
          location: locs.isNotEmpty ? locs : 'RD Congo',
          salary: salaryRaw,
          salaryCurrency: salaryCurrency,
          source: 'careerjet',
          reference: null,
        );
      }).where((j) => j.title.isNotEmpty && j.sourceUrl.isNotEmpty).toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }
}
