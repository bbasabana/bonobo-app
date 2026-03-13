import 'package:equatable/equatable.dart';

class JobOffer extends Equatable {
  final String id;
  final String title;
  final String employer;
  final String description;
  final String? deadline;
  final String sourceUrl;
  final DateTime fetchedAt;
  final String? location;
  final String? reference;
  final String? salary;
  final String? salaryCurrency;
  final String? contractType;
  /// Source : 'mediacongo' | 'careerjet' | 'option_carriere'
  final String source;

  const JobOffer({
    required this.id,
    required this.title,
    required this.employer,
    required this.description,
    this.deadline,
    required this.sourceUrl,
    required this.fetchedAt,
    this.location,
    this.reference,
    this.salary,
    this.salaryCurrency,
    this.contractType,
    this.source = 'mediacongo',
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
        'location': location,
        'reference': reference,
        'salary': salary,
        'salaryCurrency': salaryCurrency,
        'contractType': contractType,
        'source': source,
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
        location: json['location'] as String?,
        reference: json['reference'] as String?,
        salary: json['salary'] as String?,
        salaryCurrency: json['salaryCurrency'] as String?,
        contractType: json['contractType'] as String?,
        source: json['source'] as String? ?? 'mediacongo',
      );
}
