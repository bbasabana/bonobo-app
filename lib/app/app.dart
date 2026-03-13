import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';
import 'splash_screen.dart';
import 'theme.dart';
import '../core/providers/theme_provider.dart';
import '../shared/widgets/connectivity_listener.dart';
import '../shared/local_storage.dart';

class BonoboApp extends ConsumerStatefulWidget {
  const BonoboApp({super.key});

  @override
  ConsumerState<BonoboApp> createState() => _BonoboAppState();
}

class _BonoboAppState extends ConsumerState<BonoboApp> {
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    // Si le splash a déjà été vu, on passe directement à l'accueil
    if (LocalStorage.getSplashSeen()) {
      _splashComplete = true;
    }
  }

  void _onSplashComplete() {
    LocalStorage.setSplashSeen();
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
    // Le router est maintenant un Provider Riverpod pour gérer les redirections auth.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Bonobo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          ConnectivityListener(child: child ?? const SizedBox.shrink()),
    );
  }
}
