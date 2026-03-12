import 'package:equatable/equatable.dart';

class JobOffer extends Equatable {
  final String id;
  final String title;
  final String employer;
  final String description;
  final String? deadline;
  final String sourceUrl;
  final DateTime fetchedAt;

  const JobOffer({
    required this.id,
    required this.title,
    required this.employer,
    required this.description,
    this.deadline,
    required this.sourceUrl,
    required this.fetchedAt,
  });

  @override
  List<Object?> get props => [id];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'employer': employer,
        'description': description,
        'deadline': deadline,
        'sourceUrl': sourceUrl,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory JobOffer.fromJson(Map<String, dynamic> json) => JobOffer(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        employer: json['employer'] as String? ?? '',
        description: json['description'] as String? ?? '',
        deadline: json['deadline'] as String?,
        sourceUrl: json['sourceUrl'] as String? ?? '',
        fetchedAt: json['fetchedAt'] != null
            ? DateTime.tryParse(json['fetchedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
