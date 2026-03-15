import '../../../core/constants/app_config.dart';
import '../domain/sports_match.dart';

abstract class SportsService {
  Future<SportsData> fetchSportsData();
}

class ApiSportsService implements SportsService {
  final Dio _dio;

  ApiSportsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  @override
  Future<SportsData> fetchSportsData() async {
    try {
      final response = await _dio.get('/api/v1/sports');
      if (response.statusCode == 200) {
        return SportsData.fromJson(response.data);
      }
      throw Exception('Failed to load sports data');
    } catch (e) {
      // Return empty data in case of error to avoid crashes
      return SportsData(liveMatches: [], upcomingMatches: [], leagues: []);
    }
  }
}
