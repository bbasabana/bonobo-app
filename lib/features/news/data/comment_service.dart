import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_config.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/comment.dart';

class CommentService {
  final Dio _dio;
  static const String _baseUrl = AppConfig.apiBaseUrl;

  CommentService({Dio? dio, String? token})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: token != null ? {'Authorization': 'Bearer $token'} : {},
            ));

  Future<List<Comment>> fetchComments(String articleId) async {
    try {
      final res = await _dio.get('/api/v1/comments', queryParameters: {'articleId': articleId});
      final List<dynamic> data = res.data['comments'] ?? [];
      return data.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  Future<bool> postComment({
    required String articleId,
    required String content,
    String? city,
    String? region,
    String? countryCode,
  }) async {
    try {
      final res = await _dio.post('/api/v1/comments', data: {
        'articleId': articleId,
        'content': content,
        'city': city,
        'region': region,
        'countryCode': countryCode,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Error posting comment: $e');
      return false;
    }
  }
}
