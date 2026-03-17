class SportsMatch {
  final String id;
  final String competition;
  final String teamA;
  final String teamB;
  final dynamic scoreA;
  final dynamic scoreB;
  final String time;
  final String status;
  final String? logoA;
  final String? logoB;
  final String? date;

  SportsMatch({
    required this.id,
    required this.competition,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    required this.time,
    this.status = 'UPCOMING',
    this.logoA,
    this.logoB,
    this.date,
  });

  factory SportsMatch.fromJson(Map<String, dynamic> json) {
    return SportsMatch(
      id: json['id'],
      competition: json['competition'],
      teamA: json['teamA'],
      teamB: json['teamB'],
      scoreA: json['scoreA'],
      scoreB: json['scoreB'],
      time: json['time'],
      status: json['status'] ?? (json['scoreA'] != null ? 'LIVE' : 'UPCOMING'),
      logoA: json['logoA'],
      logoB: json['logoB'],
      date: json['date'],
    );
  }
}

class SportsData {
  final List<SportsMatch> liveMatches;
  final List<SportsMatch> upcomingMatches;
  final List<LeagueInfo> leagues;
  final List<SportsArticle> news;

  SportsData({
    required this.liveMatches,
    required this.upcomingMatches,
    required this.leagues,
    this.news = const [],
  });

  factory SportsData.fromJson(Map<String, dynamic> json) {
    return SportsData(
      liveMatches: (json['live_matches'] as List? ?? [])
          .map((e) => SportsMatch.fromJson(e))
          .toList(),
      upcomingMatches: (json['upcoming_matches'] as List? ?? [])
          .map((e) => SportsMatch.fromJson(e))
          .toList(),
      leagues: (json['leagues'] as List? ?? [])
          .map((e) => LeagueInfo.fromJson(e))
          .toList(),
      news: (json['news'] as List? ?? [])
          .map((e) => SportsArticle.fromJson(e))
          .toList(),
    );
  }
}

class SportsArticle {
  final String id;
  final String title;
  final String url;
  final String? imageUrl;
  final String? publishedAt;
  final String sourceName;
  final String category;

  SportsArticle({
    required this.id,
    required this.title,
    required this.url,
    this.imageUrl,
    this.publishedAt,
    required this.sourceName,
    required this.category,
  });

  factory SportsArticle.fromJson(Map<String, dynamic> json) {
    return SportsArticle(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      publishedAt: json['publishedAt'] as String?,
      sourceName: json['sourceName'] as String? ?? 'Sport',
      category: json['category'] as String? ?? 'Sport',
    );
  }
}

class LeagueInfo {
  final String id;
  final String name;
  final String logo;

  LeagueInfo({required this.id, required this.name, required this.logo});

  factory LeagueInfo.fromJson(Map<String, dynamic> json) {
    return LeagueInfo(
      id: json['id'],
      name: json['name'],
      logo: json['logo'],
    );
  }
}
