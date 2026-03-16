import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_config.dart';
import '../../../shared/local_storage.dart';
import '../../../core/services/notification_service.dart';
import 'news_providers.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));

class SyncService extends WidgetsBindingObserver {
  final Ref _ref;
  Timer? _pollingTimer;
  bool _isChecking = false;

  SyncService(this._ref);

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 45 seconds for a good balance between "real-time" and battery/bandwidth
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) => checkSync());
    // Initial check
    checkSync();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[SyncService] App resumed, checking for updates...');
      checkSync();
    }
  }

  Future<void> checkSync() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final response = await dio.get('/api/v1/sync');
      if (response.statusCode == 200) {
        final data = response.data;
        final lastMediaUpdate = data['lastMediaUpdate'] as String?;
        final lastCategoryUpdate = data['lastCategoryUpdate'] as String?;
        final latestNotification = data['latestNotification'] as Map<String, dynamic>?;

        bool needsRefresh = false;

        // Check Notifications (Push/Alerts)
        if (latestNotification != null) {
          final notifId = latestNotification['id'] as String;
          final lastSeenNotifId = LocalStorage.getLastNotificationId();

          if (lastSeenNotifId != notifId) {
            await LocalStorage.saveLastNotificationId(notifId);
            final title = latestNotification['title'] as String;
            final body = latestNotification['body'] as String;
            
            debugPrint('[SyncService] New notification detected: $title');
            
            // On affiche la notification système via le service local
            final notificationService = _ref.read(notificationServiceProvider);
            await notificationService.showRemoteNotification(
              title: title,
              body: body,
            );
          }
        }

        // Check Media Sources
        if (lastMediaUpdate != null) {
          final localMediaTs = LocalStorage.getMediaSourcesTimestamp();
          if (localMediaTs == null || DateTime.parse(lastMediaUpdate).isAfter(localMediaTs)) {
            debugPrint('[SyncService] New media sources detected!');
            needsRefresh = true;
          }
        }

        // Check Categories
        if (lastCategoryUpdate != null) {
          final localCatTs = LocalStorage.getCategoriesTimestamp();
          if (localCatTs == null || DateTime.parse(lastCategoryUpdate).isAfter(localCatTs)) {
            debugPrint('[SyncService] New categories detected!');
            needsRefresh = true;
          }
        }

        if (needsRefresh) {
          debugPrint('[SyncService] Triggering global refresh...');
          await _ref.read(refreshNewsProvider)();
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Global sync check failed: $e');
    } finally {
      _isChecking = false;
    }
  }
}
