import 'package:equatable/equatable.dart';

class AdModel extends Equatable {
  final String id;
  final String? title;
  final String imageUrl;
  final String? redirectUrl;
  final String position; // home_top | home_middle | article_details | media_details | modal
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int displayDuration;

  const AdModel({
    required this.id,
    this.title,
    required this.imageUrl,
    this.redirectUrl,
    required this.position,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.displayDuration = 5,
  });

  @override
  List<Object?> get props => [id, imageUrl, position];

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      redirectUrl: json['redirectUrl'] as String?,
      position: json['position'] as String? ?? 'home_middle',
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      displayDuration: json['displayDuration'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'redirectUrl': redirectUrl,
    'position': position,
    'isActive': isActive,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'displayDuration': displayDuration,
  };
}
