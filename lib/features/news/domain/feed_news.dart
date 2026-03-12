import 'package:equatable/equatable.dart';

class FeedNews extends Equatable {
  final String id;
  final String title;
  final String? imageUrl;
  final String excerpt;
  final String content;
  final DateTime publishedAt;
  final String sourceName;
  final String sourceId;
  final String? sourceLogo;
  final String originalUrl;
  final String? category;
  final String feedType;

  const FeedNews({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.excerpt,
    required this.content,
    required this.publishedAt,
    required this.sourceName,
    required this.sourceId,
    this.sourceLogo,
    required this.originalUrl,
    this.category,
    required this.feedType,
  });

  @override
  List<Object?> get props => [id, originalUrl];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'excerpt': excerpt,
        'content': content,
        'publishedAt': publishedAt.toIso8601String(),
        'sourceName': sourceName,
        'sourceId': sourceId,
        'sourceLogo': sourceLogo,
        'originalUrl': originalUrl,
        'category': category,
        'feedType': feedType,
      };

  factory FeedNews.fromJson(Map<String, dynamic> json) => FeedNews(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        excerpt: json['excerpt'] as String? ?? '',
        content: json['content'] as String? ?? '',
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        sourceName: json['sourceName'] as String? ?? '',
        sourceId: json['sourceId'] as String? ?? '',
        sourceLogo: json['sourceLogo'] as String?,
        originalUrl: json['originalUrl'] as String? ?? '',
        category: json['category'] as String?,
        feedType: json['feedType'] as String? ?? 'wordpress',
      );

  FeedNews copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? excerpt,
    String? content,
    DateTime? publishedAt,
    String? sourceName,
    String? sourceId,
    String? sourceLogo,
    String? originalUrl,
    String? category,
    String? feedType,
  }) =>
      FeedNews(
        id: id ?? this.id,
        title: title ?? this.title,
        imageUrl: imageUrl ?? this.imageUrl,
        excerpt: excerpt ?? this.excerpt,
        content: content ?? this.content,
        publishedAt: publishedAt ?? this.publishedAt,
        sourceName: sourceName ?? this.sourceName,
        sourceId: sourceId ?? this.sourceId,
        sourceLogo: sourceLogo ?? this.sourceLogo,
        originalUrl: originalUrl ?? this.originalUrl,
        category: category ?? this.category,
        feedType: feedType ?? this.feedType,
      );
}
