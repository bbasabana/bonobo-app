import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';
import 'splash_screen.dart';
import 'theme.dart';
import '../core/providers/theme_provider.dart';
import '../shared/widgets/connectivity_listener.dart';

class BonoboApp extends ConsumerStatefulWidget {
  const BonoboApp({super.key});

  @override
  ConsumerState<BonoboApp> createState() => _BonoboAppState();
}

class _BonoboAppState extends ConsumerState<BonoboApp> {
  bool _splashComplete = false;

  void _onSplashComplete() {
    setState(() => _splashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: BonoboSplashScreen(onComplete: _onSplashComplete),
      );
    }
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Bonobo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => ConnectivityListener(child: child ?? const SizedBox.shrink()),
    );
  }
}
