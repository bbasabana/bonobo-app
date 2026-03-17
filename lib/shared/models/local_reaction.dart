/// Modèle local pour les réactions (likes + commentaires) sur les articles.
/// Stocké en JSON dans Hive (box reactions).
class LocalComment {
  final String id;
  final String articleId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  int likes;
  bool isLikedByMe;

  LocalComment({
    required this.id,
    required this.articleId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.isLikedByMe = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'articleId': articleId,
    'authorName': authorName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes,
    'isLikedByMe': isLikedByMe,
  };

  factory LocalComment.fromJson(Map<String, dynamic> json) => LocalComment(
    id: json['id'] as String,
    articleId: json['articleId'] as String,
    authorName: json['authorName'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    likes: (json['likes'] as num?)?.toInt() ?? 0,
    isLikedByMe: json['isLikedByMe'] as bool? ?? false,
  );
}

class ArticleReaction {
  final String articleId;
  bool isLiked;
  bool isDisliked;
  int totalLikes;

  ArticleReaction({
    required this.articleId,
    this.isLiked = false,
    this.isDisliked = false,
    this.totalLikes = 0,
  });

  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'isLiked': isLiked,
    'isDisliked': isDisliked,
    'totalLikes': totalLikes,
  };

  factory ArticleReaction.fromJson(Map<String, dynamic> json) => ArticleReaction(
    articleId: json['articleId'] as String,
    isLiked: json['isLiked'] as bool? ?? false,
    isDisliked: json['isDisliked'] as bool? ?? false,
    totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
  );

  ArticleReaction copyWith({
    String? articleId,
    bool? isLiked,
    bool? isDisliked,
    int? totalLikes,
  }) {
    return ArticleReaction(
      articleId: articleId ?? this.articleId,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      totalLikes: totalLikes ?? this.totalLikes,
    );
  }
}
