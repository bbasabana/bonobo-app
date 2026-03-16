import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_service.dart';
import '../domain/category.dart';
import '../../../shared/local_storage.dart';

final categoryServiceWithDioProvider = Provider<CategoryService>((ref) => ApiCategoryService());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.watch(categoryServiceWithDioProvider);
  
  // 1. Cache first
  final cached = LocalStorage.getCategories();
  if (cached.isNotEmpty) {
     if (LocalStorage.isCategoriesExpired()) {
       _backgroundRefreshCategories(ref, service);
     }
     return cached.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 2. Fetch if no cache
  return await _fetchCategories(ref, service);
});

Future<List<Category>> _fetchCategories(Ref ref, CategoryService service) async {
  try {
    final fresh = await service.fetchCategories();
    if (fresh.isNotEmpty) {
      await LocalStorage.saveCategories(fresh.map((c) => {
        'id': c.id,
        'name': c.name,
        'slug': c.slug,
        'color': c.color,
      }).toList());
    }
    return fresh;
  } catch (_) {
    return [];
  }
}

void _backgroundRefreshCategories(Ref ref, CategoryService service) async {
  try {
    final fresh = await service.fetchCategories();
    if (fresh.isNotEmpty) {
      await LocalStorage.saveCategories(fresh.map((c) => {
        'id': c.id,
        'name': c.name,
        'slug': c.slug,
        'color': c.color,
      }).toList());
      ref.invalidate(categoriesProvider);
    }
  } catch (_) {}
}
