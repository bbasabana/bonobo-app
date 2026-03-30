import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_service.dart';
import 'core/utils/date_formatter.dart';
import 'features/news/data/backend_news_service.dart';
import 'shared/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Barre de statut transparente pour que le splash soit plein-écran ───────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0D1B12),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1B12),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Initialisation des services essentiels ──────────────────────────────────
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await LocalStorage.init();
  await initializeDateFormatting('fr');
  DateFormatter.setupLocales();

  // NotificationService et PushService : ne pas attendre PushService.init()
  // car il fait un appel réseau (registration FCM) — on le lance en parallèle
  await NotificationService().init();
  PushService().init(); // intentionnellement sans await

  // ── Pré-chauffe data : lancer AVANT runApp, en parallèle ───────────────────
  // Si le cache local est vide (premier lancement), on démarre le fetch réseau
  // pendant que Flutter monte l'arbre de widgets + affiche le splash.
  // Résultat : quand le splash se termine (~1.8 s), les articles sont déjà
  // en train d'arriver ou sont déjà prêts — l'accueil s'affiche sans attente.
  _prewarmIfEmpty();

  runApp(
    const ProviderScope(
      child: BonoboApp(),
    ),
  );
}

/// Lance le fetch articles + sources si le cache est vide.
/// S'exécute en arrière-plan sans bloquer le démarrage de l'UI.
void _prewarmIfEmpty() {
  final hasArticles = LocalStorage.getArticles().isNotEmpty;
  final hasSources  = LocalStorage.getMediaSources().isNotEmpty;
  if (!hasArticles || !hasSources) {
    _doPrewarm();
  }
}

Future<void> _doPrewarm() async {
  try {
    final service = BackendNewsService();
    // Lancer les deux fetches en parallèle
    final results = await Future.wait([
      service.fetchMediaSources().timeout(
        const Duration(seconds: 12),
        onTimeout: () => [],
      ),
      service.fetchAllFeeds().timeout(
        const Duration(seconds: 20),
        onTimeout: () => [],
      ),
    ], eagerError: false);

    final sources = results[0] as List;
    final articles = results[1] as List;

    if (sources.isNotEmpty) {
      await LocalStorage.saveMediaSources(
          sources.cast());
    }
    if (articles.isNotEmpty) {
      await LocalStorage.saveArticles(
          articles.cast());
    }
  } catch (_) {
    // Silencieux — le splash gère son propre état d'erreur
  }
}
