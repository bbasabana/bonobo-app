import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';

class JournalistApplicationService {
  final Dio _dio;
  static const String _baseUrl = AppConfig.apiBaseUrl;

  JournalistApplicationService({String? token})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ));

  Future<bool> submitJournalistApplication({
    required String type,
    required String bio,
    String? mediaName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/journalist-applications/submit',
        data: {
          'type': type,
          'bio': bio,
          if (mediaName != null) 'mediaName': mediaName,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitMediaSite({
    required String siteName,
    required String feedUrl,
    required String contactEmail,
    String? cmsType,
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/sites/submit',
        data: {
          'siteName': siteName,
          'feedUrl': feedUrl,
          'contactEmail': contactEmail,
          'cmsType': cmsType ?? 'unknown',
          if (userId != null) 'userId': userId,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getJournalistDashboard() async {
    try {
      final response = await _dio.get('/api/v1/journalist/dashboard');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> submitCertificationRequest({
    required String mediaId,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/journalist/certification-request',
        data: {
          'mediaId': mediaId,
          'type': type,
        },
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
