import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum FeedType { wordpress, rss, drupal }

class MediaSource extends Equatable {
  final String id;
  final String name;
  final String feedUrl;
  final FeedType feedType;
  final List<String> categories;
  final String country;
  final String logoUrl;
  final Color color;

  const MediaSource({
    required this.id,
    required this.name,
    required this.feedUrl,
    required this.feedType,
    required this.categories,
    required this.country,
    required this.logoUrl,
    this.color = const Color(0xFF01732C),
  });

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
    final words = name.split(RegExp(r'[\s\-]'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  /// URL du favicon via Google Favicon API.
  /// Préfixe www. si absent — améliore la résolution pour certains domaines (ex: zoom-eco.net).
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
}
