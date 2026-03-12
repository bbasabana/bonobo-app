import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../features/news/domain/feed_news.dart';
import '../features/jobs/domain/job_offer.dart';
import 'models/local_reaction.dart';

class LocalStorage {
  static late Box<String> _newsBox;
  static late Box<String> _jobsBox;
  static late Box<String> _prefsBox;
  static late Box<String> _translationBox;
  static late Box<String> _reactionsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _newsBox = await Hive.openBox<String>(AppConstants.hiveNewsBox);
    _jobsBox = await Hive.openBox<String>(AppConstants.hiveJobsBox);
    _prefsBox = await Hive.openBox<String>(AppConstants.hivePrefsBox);
    _translationBox = await Hive.openBox<String>(AppConstants.hiveTranslationBox);
    _reactionsBox = await Hive.openBox<String>('reactionsBox');
  }

  // --- News ---

  static Future<void> saveArticles(List<FeedNews> articles, {String key = AppConstants.keyArticlesAll}) async {
    final json = jsonEncode(articles.map((a) => a.toJson()).toList());
    await _newsBox.put(key, json);
    await _newsBox.put('${key}_ts', DateTime.now().toIso8601String());
  }

  static List<FeedNews> getArticles({String key = AppConstants.keyArticlesAll}) {
    final json = _newsBox.get(key);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => FeedNews.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static bool isNewsExpired({String key = AppConstants.keyArticlesAll}) {
    return _isExpired('${key}_ts', AppConstants.feedCacheTtl);
  }

  // --- Jobs ---

  static Future<void> saveJobs(List<JobOffer> jobs) async {
    final json = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await _jobsBox.put(AppConstants.keyJobsAll, json);
    await _jobsBox.put('${AppConstants.keyJobsAll}_ts', DateTime.now().toIso8601String());
  }

  static List<JobOffer> getJobs() {
    final json = _jobsBox.get(AppConstants.keyJobsAll);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => JobOffer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static bool isJobsExpired() {
    return _isExpired('${AppConstants.keyJobsAll}_ts', AppConstants.jobsCacheTtl);
  }

  // --- Subscriptions ---

  static List<String> getSubscriptions() {
    final json = _prefsBox.get(AppConstants.keySubscriptions);
    if (json == null) return [];
    try {
      return List<String>.from(jsonDecode(json) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSubscriptions(List<String> sourceIds) async {
    await _prefsBox.put(AppConstants.keySubscriptions, jsonEncode(sourceIds));
  }

  // --- Auth ---

  // --- Article font size ---

  static double getArticleFontSize() {
    final saved = _prefsBox.get('article_font_size');
    if (saved == null) return 16.0;
    return double.tryParse(saved) ?? 16.0;
  }

  static Future<void> saveArticleFontSize(double size) async {
    await _prefsBox.put('article_font_size', size.toString());
  }

  // --- Theme ---

  static ThemeMode getThemeMode() {
    final saved = _prefsBox.get('theme_mode');
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _prefsBox.put('theme_mode', value);
  }

  // --- Auth ---

  static String? getToken() => _prefsBox.get('user_token');
  static Future<void> saveToken(String token) => _prefsBox.put('user_token', token);

  static String? getUserRole() => _prefsBox.get('user_role');
  static Future<void> saveUserRole(String role) => _prefsBox.put('user_role', role);

  static Future<void> logout() async {
    await _prefsBox.delete('user_token');
    await _prefsBox.delete('user_role');
  }

  // --- Translations ---

  static String? getTranslation(String articleId) {
    final key = '${articleId}_en';
    if (_isExpired('${key}_ts', AppConstants.translationCacheTtl)) return null;
    return _translationBox.get(key);
  }

  static Future<void> saveTranslation(String articleId, String translatedText) async {
    final key = '${articleId}_en';
    await _translationBox.put(key, translatedText);
    await _translationBox.put('${key}_ts', DateTime.now().toIso8601String());
  }

  // --- Utils ---

  static bool _isExpired(String tsKey, Duration ttl) {
    final tsStr = _newsBox.get(tsKey) ?? _jobsBox.get(tsKey) ?? _translationBox.get(tsKey);
    if (tsStr == null) return true;
    final ts = DateTime.tryParse(tsStr);
    if (ts == null) return true;
    return DateTime.now().difference(ts) > ttl;
  }

  /// Force le prochain fetch à re-télécharger (marque le cache comme expiré)
  /// SANS effacer les articles. Ainsi l'UI garde les données en attendant.
  static Future<void> markNewsExpired({String key = AppConstants.keyArticlesAll}) async {
    await _newsBox.delete('${key}_ts');
  }

  // --- Saved Articles ---

  static List<String> getSavedArticleIds() {
    final json = _prefsBox.get('saved_article_ids');
    if (json == null) return [];
    try {
      return List<String>.from(jsonDecode(json) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _persistSavedIds(List<String> ids) async {
    await _prefsBox.put('saved_article_ids', jsonEncode(ids));
  }

  static List<FeedNews> getSavedArticles() {
    final json = _prefsBox.get('saved_articles_data');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => FeedNews.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addSavedArticle(FeedNews article) async {
    final ids = getSavedArticleIds();
    if (ids.contains(article.id)) return;
    ids.insert(0, article.id);
    await _persistSavedIds(ids);
    final articles = [article, ...getSavedArticles().where((a) => a.id != article.id)];
    await _prefsBox.put(
      'saved_articles_data',
      jsonEncode(articles.map((a) => a.toJson()).toList()),
    );
  }

  static Future<void> removeSavedArticle(String articleId) async {
    final ids = getSavedArticleIds()..remove(articleId);
    await _persistSavedIds(ids);
    final articles = getSavedArticles().where((a) => a.id != articleId).toList();
    await _prefsBox.put(
      'saved_articles_data',
      jsonEncode(articles.map((a) => a.toJson()).toList()),
    );
  }

  // --- Reactions (likes + commentaires) ---

  static ArticleReaction getReaction(String articleId) {
    final json = _reactionsBox.get('reaction_$articleId');
    if (json == null) return ArticleReaction(articleId: articleId);
    try {
      return ArticleReaction.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return ArticleReaction(articleId: articleId);
    }
  }

  static Future<void> saveReaction(ArticleReaction reaction) async {
    await _reactionsBox.put('reaction_${reaction.articleId}', jsonEncode(reaction.toJson()));
  }

  static List<LocalComment> getComments(String articleId) {
    final json = _reactionsBox.get('comments_$articleId');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => LocalComment.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveComments(String articleId, List<LocalComment> comments) async {
    await _reactionsBox.put('comments_$articleId', jsonEncode(comments.map((c) => c.toJson()).toList()));
  }

  // --- Utils ---

  static Future<void> clearAll() async {
    await _newsBox.clear();
    await _jobsBox.clear();
  }
}
