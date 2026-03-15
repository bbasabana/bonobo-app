class AppConstants {
  AppConstants._();

  static const Duration feedCacheTtl = Duration(hours: 3);
  static const Duration jobsCacheTtl = Duration(hours: 24);
  static const Duration sportsCacheTtl = Duration(minutes: 30);
  static const Duration translationCacheTtl = Duration(days: 7);

  // Timeouts réseau : 12s par source pour inclure les sites lents (Grands Lacs, Scoop RDC, etc.)
  static const Duration feedFetchTimeout = Duration(seconds: 12);
  static const Duration perSourceFetchTimeout = Duration(seconds: 12);
  static const Duration minRefreshInterval = Duration(minutes: 15);

  static const int heroSliderCount = 10;
  static const Duration heroAutoScrollInterval = Duration(seconds: 5);

  static const int articleExcerptLength = 150;
  // Home: augmenter le volume pour afficher > 50 articles au total.
  // 20 par source reste raisonnable tout en enrichissant fortement le flux.
  static const int maxArticlesPerFeed = 20;

  static const String hiveNewsBox = 'newsBox';
  static const String hiveJobsBox = 'jobsBox';
  static const String hiveSportsBox = 'sportsBox';
  static const String hivePrefsBox = 'prefsBox';
  static const String hiveTranslationBox = 'translationBox';

  static const String keyArticlesAll = 'articles_all';
  static const String keyMediaSourcesAll = 'media_sources_all';
  static const String keyJobsAll = 'jobs_all';
  static const String keySubscriptions = 'subscriptions';
  static const String keyLastFetch = 'last_fetch';

  static const double borderRadiusCard = 12.0;
  static const double borderRadiusButton = 24.0;
  static const double borderRadiusChip = 999.0;
}
