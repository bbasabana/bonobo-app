import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/bonobo_app_bar.dart';
import '../../../shared/widgets/offline_banner.dart';

class SportsScreen extends StatelessWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BonoboAppBar(title: 'Sport'),
      body: Column(
        children: [
          const OfflineBanner(),
          // League filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                'RDC', 'CAF', 'Premier League', 'La Liga', 'Ligue 1'
              ].map((league) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(label: Text(league)),
              )).toList(),
            ),
          ),
          // Live match banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.backgroundDark, Color(0xFF0D2E1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'EN DIRECT',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(0xFF4ADE80),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _LiveScoreCard(
                  teamA: 'RDC',
                  teamB: 'Maroc',
                  scoreA: 1,
                  scoreB: 0,
                  time: '67\'',
                  competition: 'CAN 2025',
                ),
              ],
            ),
          ),
          // Today's matches
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Matches du jour',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _MatchCard(
                  teamA: 'TP Mazembe',
                  teamB: 'AS Vita',
                  timeOrScore: '15:00',
                  competition: 'Linafoot',
                  isLive: false,
                ),
                SizedBox(height: 8),
                _MatchCard(
                  teamA: 'Arsenal',
                  teamB: 'Chelsea',
                  timeOrScore: '2 - 1',
                  competition: 'Premier League',
                  isLive: true,
                ),
                SizedBox(height: 8),
                _MatchCard(
                  teamA: 'Barcelona',
                  teamB: 'Real Madrid',
                  timeOrScore: '18:00',
                  competition: 'La Liga',
                  isLive: false,
                ),
                SizedBox(height: 8),
                _MatchCard(
                  teamA: 'PSG',
                  teamB: 'Lyon',
                  timeOrScore: '20:45',
                  competition: 'Ligue 1',
                  isLive: false,
                ),
              ],
            ),
          ),
          // API integration note
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Intégration API-Football en cours — Données temps réel disponibles avec clé API',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveScoreCard extends StatelessWidget {
  final String teamA;
  final String teamB;
  final int scoreA;
  final int scoreB;
  final String time;
  final String competition;

  const _LiveScoreCard({
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    required this.time,
    required this.competition,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          competition,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Text(
                teamA,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '$scoreA - $scoreB',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                teamB,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String teamA;
  final String teamB;
  final String timeOrScore;
  final String competition;
  final bool isLive;

  const _MatchCard({
    required this.teamA,
    required this.teamB,
    required this.timeOrScore,
    required this.competition,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2035) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLive
            ? Border.all(color: AppColors.primaryGreenStart.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teamA,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLive
                      ? AppColors.primaryGreen.withValues(alpha: 0.15)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeOrScore,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isLive ? AppColors.primaryGreenStart : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                competition,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              teamB,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
