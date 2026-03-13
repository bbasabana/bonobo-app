import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_service.dart';
import 'core/utils/date_formatter.dart';
import 'shared/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await LocalStorage.init();
  await initializeDateFormatting('fr');
  DateFormatter.setupLocales();
  await NotificationService().init();
  await PushService().init();

  runApp(
    const ProviderScope(
      child: BonoboApp(),
    ),
  );
}
