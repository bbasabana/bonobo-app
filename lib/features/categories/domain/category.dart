import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String color;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      color: json['color'] as String? ?? '#10b981',
    );
  }

  @override
  List<Object?> get props => [id, slug];
}
