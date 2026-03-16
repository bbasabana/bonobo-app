import 'package:dio/dio.dart';
import '../../../core/constants/app_config.dart';
import '../domain/category.dart';

abstract class CategoryService {
  Future<List<Category>> fetchCategories();
}

class ApiCategoryService implements CategoryService {
  final Dio _dio;

  ApiCategoryService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  @override
  Future<List<Category>> fetchCategories() async {
    try {
      final res = await _dio.get('/api/v1/categories');
      final List<dynamic> data = res.data['categories'] ?? [];
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
