import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_config.dart';
import '../domain/ad_model.dart';

final adServiceProvider = Provider((ref) => AdService());

final adsProvider = FutureProvider.family<List<AdModel>, String?>((ref, position) async {
  final service = ref.watch(adServiceProvider);
  return service.fetchAds(position: position);
});

class AdService {
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  Future<List<AdModel>> fetchAds({String? position}) async {
    try {
      final response = await _dio.get(
        '/api/v1/ads',
        queryParameters: position != null ? {'position': position} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['advertisements'] as List? ?? [];
        return data.map((json) => AdModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[AdService] Error fetching ads: $e');
      return [];
    }
  }

  Future<void> trackEvent(String adId, String type) async {
    try {
      await _dio.post('/api/v1/ads', data: {'id': adId, 'type': type});
    } catch (e) {
      print('[AdService] Error tracking ad event: $e');
    }
  }
}
