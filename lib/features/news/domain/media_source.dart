import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum FeedType { wordpress, rss, drupal, php, other }

class MediaSource extends Equatable {
  final String id;
  final String name;
  final String feedUrl;
  final FeedType feedType;
  final List<String> categories;
  final String country;
  final String logoUrl;
  final Color color;
  final String? cmsType;
  final String certification; // none | blue | green | yellow | red
  final String certificationRequestStatus; // none | pending | approved | rejected

  const MediaSource({
    required this.id,
    required this.name,
    required this.feedUrl,
    required this.feedType,
    required this.categories,
    required this.country,
    required this.logoUrl,
    this.color = const Color(0xFF01732C),
    this.cmsType,
    this.certification = 'none',
    this.certificationRequestStatus = 'none',
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    FeedType type = FeedType.other;
    final typeStr = json['feedType']?.toString().toLowerCase();
    if (typeStr == 'wordpress') type = FeedType.wordpress;
    if (typeStr == 'rss') type = FeedType.rss;
    if (typeStr == 'drupal') type = FeedType.drupal;

    return MediaSource(
      id: json['id'] as String,
      name: json['name'] as String,
      feedUrl: json['feedUrl'] as String,
      feedType: type,
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      country: json['country'] as String? ?? 'CD',
      logoUrl: json['logoUrl'] as String? ?? '',
      cmsType: json['cmsType'] as String?,
      color: json['color'] != null ? _parseColor(json['color'] as String) : const Color(0xFF01732C),
      certification: json['certification'] as String? ?? 'none',
      certificationRequestStatus: json['certificationRequestStatus'] as String? ?? 'none',
    );
  }

  static Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      return const Color(0xFF01732C);
    } catch (_) {
      return const Color(0xFF01732C);
    }
  }

  MediaSource copyWith({
    String? id,
    String? name,
    String? feedUrl,
    FeedType? feedType,
    List<String>? categories,
    String? country,
    String? logoUrl,
    Color? color,
    String? cmsType,
    String? certification,
    String? certificationRequestStatus,
  }) {
    return MediaSource(
      id: id ?? this.id,
      name: name ?? this.name,
      feedUrl: feedUrl ?? this.feedUrl,
      feedType: feedType ?? this.feedType,
      categories: categories ?? this.categories,
      country: country ?? this.country,
      logoUrl: logoUrl ?? this.logoUrl,
      color: color ?? this.color,
      cmsType: cmsType ?? this.cmsType,
      certification: certification ?? this.certification,
      certificationRequestStatus: certificationRequestStatus ?? this.certificationRequestStatus,
    );
  }

  /// Label lisible du pays (sans emoji).
  String get countryLabel {
    switch (country) {
      case 'CD': return 'RDC';
      case 'BI': return 'Burundi';
      case 'CG': return 'Congo';
      default:   return country;
    }
  }

  String get initials {
    if (name.isEmpty) return '??';
    final words = name.split(RegExp(r'[\s\-]'));
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  /// URL du favicon via Google Favicon API.
  String get faviconUrl {
    try {
      final uri = Uri.parse(feedUrl);
      final host = uri.host.startsWith('www.') ? uri.host : 'www.${uri.host}';
      return 'https://www.google.com/s2/favicons?domain=$host&sz=64';
    } catch (_) {
      return '';
    }
  }

  @override
  List<Object?> get props => [id];

  IconData? get certificationIcon {
    switch (certification) {
      case 'blue': return Icons.verified_rounded;
      case 'green': return Icons.verified_user_rounded;
      case 'yellow': return Icons.report_problem_rounded;
      case 'red': return Icons.warning_rounded;
      default: return null;
    }
  }

  Color get certificationColor {
    switch (certification) {
      case 'blue': return Colors.blue;
      case 'green': return Colors.emerald;
      case 'yellow': return Colors.amber;
      case 'red': return Colors.red;
      default: return Colors.transparent;
    }
  }
}
