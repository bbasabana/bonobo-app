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

  SportsData({
    required this.liveMatches,
    required this.upcomingMatches,
    required this.leagues,
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
