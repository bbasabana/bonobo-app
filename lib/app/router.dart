import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/news/presentation/screens/home_screen.dart';
import '../features/news/presentation/screens/article_detail_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/jobs/presentation/jobs_screen.dart';
import '../features/sports/presentation/sports_screen.dart';
import '../features/journalist/presentation/journalist_screen.dart';
import '../features/media/presentation/media_detail_screen.dart';
import '../features/media/presentation/media_picker_screen.dart';
import '../features/account/presentation/compte_screen.dart';
import '../features/news/presentation/screens/search_screen.dart';
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

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
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
      ],
    ),
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
  ],
);
