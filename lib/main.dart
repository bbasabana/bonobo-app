import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/utils/date_formatter.dart';
import 'shared/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorage.init();
  await initializeDateFormatting('fr');
  DateFormatter.setupLocales();

  runApp(
    const ProviderScope(
      child: BonoboApp(),
    ),
  );
}
