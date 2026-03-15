import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String content;
  final String status;
  final DateTime createdAt;
  final String articleId;
  final CommentAuthor author;

  const Comment({
    required this.id,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.articleId,
    required this.author,
  });

  @override
  List<Object?> get props => [id];

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      status: json['status'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
      articleId: json['articleId'] as String,
      author: CommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}

class CommentAuthor extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const CommentAuthor({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id];

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      id: json['id'] as String,
      displayName: (json['displayName'] as String?) ?? 'Utilisateur',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
