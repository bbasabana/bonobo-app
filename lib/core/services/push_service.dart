import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_config.dart';
import '../../shared/local_storage.dart';
import 'notification_service.dart';

/// Service de messagerie push (FCM) Bonobo.
///
/// Flux production :
///   1. Demander la permission FCM
///   2. Récupérer le token FCM
///   3. Enregistrer le token sur le backend (POST /api/v1/push/register-device)
///   4. Écouter les messages entrants → afficher une notification locale riche
///   5. Au tap → naviguer vers l'article concerné
class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Clé de navigation globale pour les navigations depuis un background tap.
  static final navigatorKey = GlobalKey<NavigatorState>();
  static String? _pendingArticleId;

  // ── Initialisation ──────────────────────────────────────────────────────────

  Future<void> init() async {
    await _requestPermission();

    // Récupérer et enregistrer le token
    final token = await _messaging.getToken();
    debugPrint('\n🚀 [PushService] FCM TOKEN : $token\n'); 
    
    if (token != null) {
      await _registerDeviceToken(token);
    }

    // Actualisation automatique du token
    _messaging.onTokenRefresh.listen(_registerDeviceToken);

    // Foreground : messages reçus quand l'app est ouverte
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background/terminated : notification tappée → ouvrir l'article
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTapped);

    // Cas spécial : app lancée depuis une notification (app était terminée)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingArticleId = initialMessage.data['articleId'];
      final pushLogId = initialMessage.data['pushLogId'];
      if (pushLogId != null) {
        _trackEvent(pushLogId, 'click');
      }
    }
  }

  /// Consommer l'articleId en attente lors du premier build du router.
  static String? consumePendingArticleId() {
    final id = _pendingArticleId;
    _pendingArticleId = null;
    return id;
  }

  // ── Permission ──────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      provisional: false,
      criticalAlert: false,
    );
    debugPrint('[PushService] Permission: ${settings.authorizationStatus}');
  }

  // ── Enregistrement du token au backend ─────────────────────────────────────

  Future<void> _registerDeviceToken(String fcmToken) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Content-Type': 'application/json'},
      ));

      final userToken = LocalStorage.getToken();
      final platform = Platform.isIOS ? 'ios' : 'android';

      await dio.post(
        '/api/v1/push/register-device',
        data: {
          'token': fcmToken,
          'platform': platform,
          'appVersion': '1.0.0',
          'locale': Platform.localeName,
        },
        options: Options(
          headers: userToken != null
              ? {'Authorization': 'Bearer $userToken'}
              : null,
        ),
      );
      debugPrint('[PushService] Token enregistré sur le backend.');
    } catch (e) {
      // Erreur silencieuse — sera réessayée au prochain lancement
      debugPrint('[PushService] Enregistrement token échoué: $e');
    }
  }

  // ── Tracking ───────────────────────────────────────────────────────────────

  Future<void> _trackEvent(String pushLogId, String type) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        headers: {'Content-Type': 'application/json'},
      ));

      final token = LocalStorage.getToken();
      final platform = Platform.isIOS ? 'ios' : 'android';

      await dio.post(
        '/api/v1/push/track',
        data: {
          'pushLogId': pushLogId,
          'type': type,
          'platform': platform,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      debugPrint('[PushService] Event tracked: $type for $pushLogId');
    } catch (e) {
      debugPrint('[PushService] Track failed: $e');
    }
  }

  // ── Foreground message (app ouverte) ───────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    // FCM ne montre PAS automatiquement une notification en foreground.
    // On la crée toujours nous-mêmes ici.
    final notif = message.notification;
    final title = notif?.title
        ?? message.data['title'] as String?
        ?? 'Bonobo';
    final body = notif?.body
        ?? message.data['body'] as String?
        ?? '';
    final imageUrl = notif?.android?.imageUrl
        ?? notif?.apple?.imageUrl
        ?? message.data['imageUrl'] as String?;
    final articleId = message.data['articleId'] as String?;
    final pushLogId = message.data['pushLogId'] as String?;

    if (pushLogId != null) {
      _trackEvent(pushLogId, 'open');
    }

    await NotificationService().showRemoteNotification(
      title: title,
      body: body,
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
      articleId: articleId,
    );
  }

  // ── Tap sur notification (app en arrière-plan ou ouverte) ──────────────────

  void _onMessageTapped(RemoteMessage message) {
    final articleId = message.data['articleId'] as String?;
    final pushLogId = message.data['pushLogId'] as String?;

    if (pushLogId != null) {
      _trackEvent(pushLogId, 'click');
    }

    if (articleId != null && articleId.isNotEmpty) {
      _navigateToArticle(articleId);
    }
  }

  static void _navigateToArticle(String articleId) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.push('/article/${Uri.encodeComponent(articleId)}');
    } else {
      // App pas encore montée → stocker pour navigation différée
      _pendingArticleId = articleId;
    }
  }
}

// ── Handler de background (app EN ARRIÈRE-PLAN ou DATA-ONLY) ───────────────────
//
// Quand l'app est complètement FERMÉE et que FCM envoie un message avec un bloc
// `notification` (titre + corps), Android affiche la notification directement via
// l'OS — ce handler N'est PAS appelé dans ce cas.
//
// Ce handler est appelé pour :
//   1. Messages DATA-ONLY (sans bloc `notification`) quand l'app est en background
//   2. Certains messages en background selon la version FCM
//
// Règle : on ne crée une notification locale que si l'OS ne l'a pas déjà affichée
// (i.e. message.notification == null → data-only).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Obligatoire : initialiser Firebase dans l'isolate background
  await Firebase.initializeApp();

  final notif = message.notification;

  // Pour les messages notification+data, l'OS Android affiche déjà la notif.
  // On incrémente juste le badge sans doubler la notification.
  if (notif != null) {
    NotificationService.badgeCount++;
    try {
      await NotificationService().init();
      await NotificationService().updateBadge(NotificationService.badgeCount);
    } catch (_) {}
    debugPrint('[PushService] Background: badge incrémenté (OS gère l\'affichage).');
    return;
  }

  // Message DATA-ONLY : on affiche nous-mêmes la notification
  final title = message.data['title'] as String? ?? 'Bonobo';
  final body  = message.data['body']  as String? ?? '';
  final imageUrl  = message.data['imageUrl']  as String?;
  final articleId = message.data['articleId'] as String?;

  try {
    await NotificationService().init();
    await NotificationService().showRemoteNotification(
      title: title,
      body: body,
      imageUrl: imageUrl,
      articleId: articleId,
    );
  } catch (e) {
    debugPrint('[PushService] Background showRemoteNotification error: $e');
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService());
