import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../data/match_alert_service.dart';
import '../data/sports_service.dart';
import '../domain/sports_match.dart';

final sportsServiceProvider = Provider<SportsService>((ref) => ApiSportsService());

final sportsDataProvider = FutureProvider<SportsData>((ref) async {
  final service = ref.watch(sportsServiceProvider);
  return await service.fetchSportsData();
});

final refreshSportsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(sportsDataProvider);
    await ref.read(sportsDataProvider.future);
  };
});

final matchAlertServiceProvider = Provider<MatchAlertService>((ref) {
  final notifications = ref.watch(notificationServiceProvider);
  return MatchAlertService(notifications);
});
