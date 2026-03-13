import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/careerjet_jobs_service.dart';
import '../data/mediacongo_jobs_service.dart';
import '../domain/job_offer.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/local_storage.dart';

final mediacongoJobsServiceProvider =
    Provider<MediacongoJobsService>((ref) => MediacongoJobsService());

final careerjetJobsServiceProvider =
    Provider<CareerjetJobsService>((ref) => CareerjetJobsService());

/// Fusionne les offres de mediacongo.net + Careerjet API.
/// Cache Hive 24h — retourne le cache si disponible et non expiré.
final jobsListProvider = FutureProvider<List<JobOffer>>((ref) async {
  final cached = LocalStorage.getJobs();
  if (cached.isNotEmpty && !LocalStorage.isJobsExpired()) {
    return cached;
  }

  final mediaService = ref.watch(mediacongoJobsServiceProvider);
  final careerService = ref.watch(careerjetJobsServiceProvider);

  final results = await Future.wait([
    mediaService.fetchJobs().timeout(
      const Duration(seconds: 20),
      onTimeout: () => <JobOffer>[],
    ),
    careerService.fetchJobs(pageSize: 50).timeout(
      const Duration(seconds: 20),
      onTimeout: () => <JobOffer>[],
    ),
  ]);

  final mediaJobs = results[0];
  final careerJobs = results[1];

  // Fusionner : mediacongo en premier (certifiés), puis careerjet
  final merged = <JobOffer>[...mediaJobs, ...careerJobs];

  // Dédupliquer par sourceUrl
  final seen = <String>{};
  final deduped = merged.where((j) => seen.add(j.sourceUrl)).toList();

  if (deduped.isNotEmpty) {
    final previousCount = cached.length;
    await LocalStorage.saveJobs(deduped);
    // Son + notification si nouvelles offres
    final newCount = deduped.length - previousCount;
    if (newCount > 0) {
      final notif = NotificationService();
      await notif.playSummarySound();
      await notif.showNewJobsNotification(count: newCount);
    }
  }

  return deduped.isNotEmpty ? deduped : cached;
});

/// Rafraîchir les offres (pull-to-refresh).
final refreshJobsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final mediaService = ref.read(mediacongoJobsServiceProvider);
    final careerService = ref.read(careerjetJobsServiceProvider);

    final results = await Future.wait([
      mediaService.fetchJobs().timeout(
        const Duration(seconds: 20),
        onTimeout: () => <JobOffer>[],
      ),
      careerService.fetchJobs(pageSize: 50).timeout(
        const Duration(seconds: 20),
        onTimeout: () => <JobOffer>[],
      ),
    ]);

    final merged = <JobOffer>[...results[0], ...results[1]];
    final seen = <String>{};
    final deduped = merged.where((j) => seen.add(j.sourceUrl)).toList();

    if (deduped.isNotEmpty) {
      await LocalStorage.saveJobs(deduped);
    }
    ref.invalidate(jobsListProvider);
  };
});
