import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/image_downloader.dart';

/// Service centralisé de notifications locales Bonobo.
/// Version compatible avec flutter_local_notifications: ^21.0.0
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Compteur badge cumulé — réinitialisé à l'ouverture de l'app.
  static int badgeCount = 0;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Note v21 : initialize() exige des paramètres nommés (settings:)
    await _localNotif.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        debugPrint('[NotificationService] tap payload: ${r.payload}');
      },
    );

    // Initialiser le badgeCount depuis le stockage
    final prefs = await SharedPreferences.getInstance();
    badgeCount = prefs.getInt('notification_badge_count') ?? 0;

    if (Platform.isAndroid) {
      final plugin = _localNotif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      // Permission API 33+
      await plugin?.requestNotificationsPermission();

      // Créer les canaux Android (indispensable pour Android 8+)
      // Note : Ajout du suffixe _v2 pour forcer Android à recréer le profil avec son et vibration
      await plugin?.createNotificationChannel(const AndroidNotificationChannel(
        'bonobo_articles_v2',
        'Nouveaux articles',
        description: 'Nouveaux articles Bonobo',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('new_articles'),
      ));
      await plugin?.createNotificationChannel(const AndroidNotificationChannel(
        'bonobo_remote_v2',
        'Notifications Bonobo',
        description: 'Notifications push FCM',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('new_articles'),
      ));
      await plugin?.createNotificationChannel(const AndroidNotificationChannel(
        'bonobo_jobs_v2',
        'Offres d\'emploi',
        description: 'Nouvelles offres d\'emploi',
        importance: Importance.defaultImportance,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('summary_notification'),
      ));
      await plugin?.createNotificationChannel(const AndroidNotificationChannel(
        'bonobo_sports_v2',
        'Matchs en direct',
        description: 'Alertes pour vos matchs de football',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('new_articles'),
      ));
    }
  }

  // ── Notification "nouveaux articles" ──────────────────────────────────────────

  Future<void> showNewArticlesNotification({
    required int count,
    String? sourceName,
  }) async {
    if (!_initialized) await init();
    final prefs = await SharedPreferences.getInstance();
    badgeCount = (prefs.getInt('notification_badge_count') ?? 0) + count;
    await prefs.setInt('notification_badge_count', badgeCount);
    updateBadge(badgeCount);

    final body = sourceName != null
        ? '$count nouv. article${count > 1 ? 's' : ''} — $sourceName'
        : '$count nouvel${count > 1 ? 'les' : ''} article${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''}';

    // Note v21 : show() utilise des paramètres nommés (id:, title:, body:, notificationDetails:)
    await _localNotif.show(
      id: 1001,
      title: 'Bonobo',
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'bonobo_articles_v2',
          'Nouveaux articles',
          channelDescription: 'Nouveaux articles Bonobo',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          sound: const RawResourceAndroidNotificationSound('new_articles'),
          number: badgeCount,
          channelShowBadge: true,
          color: const Color(0xFF1EB45A),
          groupKey: 'com.meyllos.bonobo.ARTICLES',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          sound: 'new_articles.caf',
        ),
      ),
    );
  }

  // ── Notification push FCM enrichie ────────────────────────────────────────────

  Future<void> showRemoteNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? articleId,
    int? badgeCount,
  }) async {
    if (!_initialized) await init();
    final prefs = await SharedPreferences.getInstance();
    if (badgeCount != null) {
      NotificationService.badgeCount = badgeCount;
    } else {
      NotificationService.badgeCount = (prefs.getInt('notification_badge_count') ?? 0) + 1;
    }
    await prefs.setInt('notification_badge_count', NotificationService.badgeCount);
    updateBadge(NotificationService.badgeCount);

    StyleInformation? styleInformation;
    String? downloadedImagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      downloadedImagePath = await ImageDownloader.downloadImage(
          imageUrl, 'push_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      if (downloadedImagePath != null) {
        styleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(downloadedImagePath),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          contentTitle: title,
          summaryText: body,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );
      }
    }

    styleInformation ??= BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: articleId != null ? 'Appuyez pour lire' : null,
    );

    await _localNotif.show(
      id: 2001,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'bonobo_remote_v2',
          'Notifications Bonobo',
          channelDescription: 'Notifications push FCM',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 250, 150, 250]),
          sound: const RawResourceAndroidNotificationSound('new_articles'),
          number: NotificationService.badgeCount,
          channelShowBadge: true,
          color: const Color(0xFF1EB45A),
          ticker: title,
          groupKey: 'com.meyllos.bonobo.ARTICLES',
          styleInformation: styleInformation,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          sound: 'new_articles.caf',
          badgeNumber: NotificationService.badgeCount,
          subtitle: articleId != null ? 'Appuyez pour lire' : null,
        ),
      ),
      payload: articleId,
    );

    // Show Group Summary for Android to ensure proper grouping behavior
    if (Platform.isAndroid) {
      await _showGroupSummary();
    }
  }

  Future<void> _showGroupSummary() async {
    await _localNotif.show(
      id: 0,
      title: '',
      body: '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'bonobo_remote_v2',
          'Notifications Bonobo',
          groupKey: 'com.meyllos.bonobo.ARTICLES',
          setAsGroupSummary: true,
          importance: Importance.min,
          priority: Priority.min,
          showWhen: false,
          autoCancel: true,
        ),
      ),
    );
  }

  // ── Notification offres d'emploi ───────────────────────────────────────────────

  Future<void> showNewJobsNotification({required int count}) async {
    if (!_initialized) await init();

    final body =
        '$count nouvelle${count > 1 ? 's' : ''} offre${count > 1 ? 's' : ''} d\'emploi disponible${count > 1 ? 's' : ''}';

    await _localNotif.show(
      id: 1002,
      title: 'Emplois RDC',
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'bonobo_jobs_v2',
          'Offres d\'emploi',
          channelDescription: 'Nouvelles offres d\'emploi',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
          sound:
              const RawResourceAndroidNotificationSound('summary_notification'),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: false,
          sound: 'summary_notification.caf',
        ),
      ),
    );
  }

  // ── Notification alertes matchs ────────────────────────────────────────────────

  Future<void> showMatchAlertNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    await _localNotif.show(
      id: 3001 + (payload?.hashCode ?? 0) % 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'bonobo_sports_v2',
          'Matchs en direct',
          channelDescription: 'Alertes pour vos matchs de football',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          sound: const RawResourceAndroidNotificationSound('new_articles'),
          color: const Color(0xFF1EB45A),
          category: AndroidNotificationCategory.event,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          sound: 'new_articles.caf',
        ),
      ),
      payload: payload,
    );
  }

  // ── Sons in-app (Rétro-compatibilité) ──────────────────────────────────────────

  Future<void> playNewArticlesSound() async {
    debugPrint('[NotificationService] playNewArticlesSound (no-op)');
  }

  Future<void> playSummarySound() async {
    debugPrint('[NotificationService] playSummarySound (no-op)');
  }

  Future<void> updateBadge(int count) async {
    if (await FlutterAppBadgeControl.isAppBadgeSupported()) {
      if (count <= 0) {
        FlutterAppBadgeControl.removeBadge();
      } else {
        FlutterAppBadgeControl.updateBadgeCount(count);
      }
    }
  }

  Future<void> clearBadge() async {
    badgeCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_badge_count', 0);
    updateBadge(0);
  }

  Future<void> dispose() async {}
}

// ── Provider ──────────────────────────────────────────────────────────────────
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});
