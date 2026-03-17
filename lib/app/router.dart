import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/login_screen.dart';
import '../features/news/presentation/screens/home_screen.dart';
import '../features/news/presentation/screens/article_detail_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/jobs/presentation/jobs_screen.dart';
import '../features/sports/presentation/sports_screen.dart';
import '../features/journalist/presentation/journalist_screen.dart';
import '../features/journalist/presentation/journalist_profile_screen.dart';
import '../features/media/presentation/media_detail_screen.dart';
import '../features/media/presentation/media_picker_screen.dart';
import '../features/account/presentation/compte_screen.dart';
import '../features/account/presentation/notifications_screen.dart';
import '../features/news/presentation/screens/saved_articles_screen.dart';
import '../features/news/presentation/screens/search_screen.dart';
import '../features/about/presentation/screens/about_screen.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Transition douce et animée pour les écrans (fade + léger slide).
CustomTransitionPage _buildSoftTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      final fade = CurvedAnimation(parent: animation, curve: curve);
      final slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: curve));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
  );
}

/// Provider GoRouter qui observe l'état auth pour les redirections.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final path = state.matchedLocation;

      // Seule la page /compte est protégée — redirige vers /login si pas connecté.
      if (path == '/compte' && !isAuthenticated) return '/login';

      // Si connecté et sur /login → retour à l'accueil.
      if (path == '/login' && isAuthenticated) return '/';

      return null;
    },
    refreshListenable: _RouterAuthNotifier(ref),
    routes: [
      // ── Page de login (racine) ───────────────────────────────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                    parent: animation, curve: Curves.easeIn),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
      ),

      // ── Shell avec barre de navigation ──────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CategoriesScreen()),
          ),
          GoRoute(
            path: '/jobs',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: JobsScreen()),
          ),
          GoRoute(
            path: '/sports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SportsScreen()),
          ),
          GoRoute(
            path: '/journalist',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: JournalistScreen()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AboutScreen()),
          ),
        ],
      ),

      // ── Écrans sans barre de nav ─────────────────────────────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/article/:id',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _buildSoftTransition(
            ArticleDetailScreen(
              articleId: state.pathParameters['id'] ?? '',
              extra: extra,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/media/:id',
        pageBuilder: (context, state) {
          return _buildSoftTransition(
            MediaDetailScreen(sourceId: state.pathParameters['id'] ?? ''),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/media-picker',
        pageBuilder: (context, state) {
          return _buildSoftTransition(const MediaPickerScreen());
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/compte',
        pageBuilder: (context, state) {
          return _buildSoftTransition(const CompteScreen());
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/search',
        pageBuilder: (context, state) {
          return _buildSoftTransition(const SearchScreen());
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/saved-articles',
        pageBuilder: (context, state) {
          return _buildSoftTransition(const SavedArticlesScreen());
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        pageBuilder: (context, state) {
          return _buildSoftTransition(const NotificationsScreen());
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/journalist/:id',
        pageBuilder: (context, state) {
          return _buildSoftTransition(
            JournalistProfileScreen(
                journalistId: state.pathParameters['id'] ?? ''),
          );
        },
      ),
    ],
  );
});

/// Backward-compatible export pour app.dart
GoRouter get appRouter => throw UnimplementedError(
    'Use appRouterProvider instead — see app.dart update');

/// Notifier qui signale au router de se « rafraîchir » quand l'auth change.
class _RouterAuthNotifier extends ChangeNotifier {
  _RouterAuthNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
