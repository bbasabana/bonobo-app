import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/local_storage.dart';
import '../domain/sports_match.dart';

class MatchAlertService {
  final NotificationService _notifications;

  MatchAlertService(this._notifications);

  bool isAlertEnabled(String matchId) {
    return LocalStorage.getMatchAlertIds().contains(matchId);
  }

  Future<void> toggleAlert(SportsMatch match) async {
    final matchId = match.id;
    final currentlyEnabled = isAlertEnabled(matchId);

    if (currentlyEnabled) {
      // Logic to cancel notification would go here if we used scheduled notifications
      // For now, we simulate the "Toggle" and persistence
      await LocalStorage.toggleMatchAlert(matchId);
    } else {
      await LocalStorage.toggleMatchAlert(matchId);
      
      // Schedule or show immediate notification for demo
      // In a real app, this would be a scheduled notification
      await _notifications.showMatchAlertNotification(
        title: 'Alerte Match: ${match.teamA} vs ${match.teamB}',
        body: 'Le match commence bientôt ! Tenez-vous prêt.',
        payload: matchId,
      );
    }
  }
}
