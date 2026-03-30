import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/media_favicon.dart';
import '../../../../shared/widgets/media_favicon.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../domain/media_source.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/ad_placeholder.dart';
import '../../../../shared/widgets/bonobo_article_image.dart';
import '../../../../shared/widgets/bonobo_soft_toast.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../media/presentation/devenir_media_source_modal.dart';
import '../../domain/feed_news.dart';
import '../../providers/news_providers.dart';
import '../../providers/sync_provider.dart';
import '../../../categories/domain/category.dart' as domain;
import '../../../categories/providers/category_providers.dart';
import '../widgets/article_card.dart';
import '../widgets/hero_slider_widget.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../account/presentation/widgets/journalist_modals.dart';
import '../../../ads/domain/ad_model.dart';
import '../../../ads/providers/ad_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Hauteur du hero : 42 % de la hauteur d'écran, borné entre 260 et 420 px.
// Calculé dynamiquement dans _buildBody().
const double _kHeroHeightFallback = 360.0;

// ── Catégories statiques de secours (utilisées si le fetch échoue ou pendant le premier chargement)
const _fallbackCategories = [
  (null, Icons.public_rounded, 'Tout'),
  ('Politique', Icons.account_balance_rounded, 'Politique'),
  ('Économie', Icons.trending_up_rounded, 'Économie'),
  ('Sport', Icons.sports_soccer_rounded, 'Sport'),
  ('Société', Icons.groups_rounded, 'Société'),
  ('International', Icons.language_rounded, 'International'),
  ('Culture', Icons.theater_comedy_rounded, 'Culture'),
  ('Sécurité', Icons.shield_rounded, 'Sécurité'),
  ('Santé', Icons.medical_services_rounded, 'Santé'),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _appBarSolid = false;
  String? _selectedCategory;
  bool _hasShownSavedToast = false;
  bool _justReconnected = false;

  // Cache pour éviter les sauts d'UI lors du refresh
  List<FeedNews> _lastArticles = [];
  List<FeedNews> _lastHero = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initialiser le service de synchronisation temps-réel et vérifier les pubs modales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).start();
      _checkForModalAd();
    });
  }

  void _onScroll() {
    final solid = _scrollController.offset > 20;
    if (solid != _appBarSolid) setState(() => _appBarSolid = solid);
  }

  void _checkForModalAd() async {
    try {
      final ads = await ref.read(adServiceProvider).fetchAds(position: 'modal');
      if (ads.isNotEmpty && mounted) {
        final ad = ads.first;
        _showModalAd(ad);
      }
    } catch (_) {}
  }

  void _showModalAd(AdModel ad) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // Track view
        ref.read(adServiceProvider).trackEvent(ad.id, 'view');
        
        // Auto-close after duration
        Future.delayed(Duration(seconds: ad.displayDuration), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (ad.redirectUrl != null) {
                    final url = Uri.parse(ad.redirectUrl!);
                    if (await canLaunchUrl(url)) {
                      ref.read(adServiceProvider).trackEvent(ad.id, 'click');
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  }
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    ad.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Arrêter le service de synchronisation
    ref.read(syncServiceProvider).stop();
    super.dispose();
  }

  /// Layout multi-style avec bounds-safe : grille 2, vedette, liste, etc.
  List<Widget> _buildMixedLayout(List<FeedNews> articles, BuildContext ctx, double heroHeight) {
    final slivers = <Widget>[];
    final total = articles.length;
    if (total == 0) return slivers;
    var i = 0;

    int take(int n) => (total - i).clamp(0, n);

    Widget header(String title, String sub) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );

    void addGrid2(int count) {
      final n = take(count);
      if (n <= 0) return;
      final start = i;
      // Ratio adaptatif : on laisse la carte gérer sa propre hauteur via mainAxisExtent.
      // mainAxisExtent = image height (calculée dans ArticleGridCard) + texte (≈80px)
      final screenW = MediaQuery.sizeOf(ctx).width;
      final tileW = (screenW - 46) / 2;
      final imgH = (tileW * 0.70).clamp(90.0, 160.0);
      final tileH = imgH + 80; // image + titre 2 lignes + date
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 14,
            mainAxisExtent: tileH,
          ),
          delegate: SliverChildBuilderDelegate((_, idx) => ArticleGridCard(article: articles[start + idx]), childCount: n),
        ),
      ));
      i += n;
    }

    void addFeatured() {
      if (i >= total) return;
      slivers.add(SliverToBoxAdapter(child: ArticleFeaturedCard(article: articles[i])));
      i++;
    }

    void addList(int count) {
      final n = take(count);
      if (n <= 0) return;
      final start = i;
      slivers.add(SliverList(delegate: SliverChildBuilderDelegate(
        (_, idx) => ArticleListCard(article: articles[start + idx], showBadge: getTimeGroup(articles[start + idx].publishedAt) == TimeGroup.lessThanOneHour),
        childCount: n,
      )));
      i += n;
    }

    void addCondensed() {
      if (i >= total) return;
      final start = i;
      final n = total - start;
      slivers.add(SliverList(delegate: SliverChildBuilderDelegate(
        (_, idx) => ArticleCondensedCard(article: articles[start + idx]),
        childCount: n,
      )));
      i += n;
    }

    // ── Grille 2 col (4)
    addGrid2(4);
    // ── Vedette
    addFeatured();
    // ── Liste (3)
    addList(3);
    // ── Bannière Journaliste
    slivers.add(SliverToBoxAdapter(
      child: _JournalistBanner(
        onTap: () {
          final auth = ref.read(authProvider);
          if (!auth.isAuthenticated) {
            context.push('/compte');
            BonoboSoftToast.show(context, message: 'Connectez-vous pour postuler.', icon: Icons.info_outline_rounded, iconColor: AppColors.primaryGreenStart);
          } else if (auth.role == 'user') {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const JournalistApplicationModal(),
            );
          } else {
            context.push('/journalist');
          }
        },
      ),
    ));
    // ── Grille 2 col (4)
    addGrid2(4);
    slivers.add(const SliverToBoxAdapter(child: BonoboAdWidget(position: 'home_top', height: 60, label: 'Espace publicitaire')));
    // ── Vedette
    addFeatured();
    // ── Liste (5)
    addList(5);
    // ── Grille 2 col (4)
    if (i < total) {
      slivers.add(header('Plus d\'actualités', 'Hier et au-delà'));
      addGrid2(4);
    }
    // ── Vedette
    addFeatured();
    // ── Pub 2
    if (i < total) {
      slivers.add(const SliverToBoxAdapter(child: BonoboAdWidget(position: 'home_middle', height: 60, label: 'Espace publicitaire')));
    }
    // ── Liste (5)
    addList(5);
    // ── Grille 2 col (4)
    addGrid2(4);
    // ── Reste en condensé
    if (i < total) {
      slivers.add(header('À découvrir', 'Encore plus de contenu'));
      addCondensed();
    }

    return slivers;
  }

  List<FeedNews> _filterArticles(List<FeedNews> all) {
    if (_selectedCategory == null) return all;
    return all.where((a) {
      if (a.category == null) return false;
      final cats = a.category!.toLowerCase();
      final target = _selectedCategory!.toLowerCase();
      // Handle comma-separated categories from NewsService
      return cats.split(', ').any((c) => c.trim() == target) || cats.contains(target);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsListProvider);
    final heroAsync = ref.watch(heroArticlesProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final isRefreshing = ref.watch(newsRefreshingProvider);
    final lastError = ref.watch(newsLastErrorProvider);
    final statusBarH = MediaQuery.of(context).padding.top;

    // Mettre à jour les données persistantes (pattern Facebook/Twitter)
    final currentArticles = newsAsync.valueOrNull;
    if (currentArticles != null && currentArticles.isNotEmpty) {
      _lastArticles = currentArticles;
    }
    final currentHero = heroAsync.valueOrNull;
    if (currentHero != null && currentHero.isNotEmpty) {
      _lastHero = currentHero;
    }
    final articles = _lastArticles;
    final heroArticles = _lastHero;
    final hasData = articles.isNotEmpty;

    // Shimmer si on charge ET qu'on n'a pas encore de données
    // (couvre aussi le cas "refresh depuis état vide")
    final isLoading = newsAsync.isLoading || isRefreshing;
    final isFirstLoad = !hasData && isLoading;

    ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      final wasOnline = previous?.valueOrNull ?? true;
      final nowOnline = next.valueOrNull ?? false;
      if (!wasOnline && nowOnline && mounted) {
        _justReconnected = true;
        ref.read(refreshNewsProvider)();
      }
    });

    ref.listen<String?>(newsLastErrorProvider, (prev, next) {
      if (next != null && mounted) {
        BonoboSoftToast.show(context,
          message: hasData
              ? '$next. Données en cache affichées.'
              : 'Impossible de charger les actualités. Vérifiez votre connexion.',
          icon: hasData ? Icons.info_outline_rounded : Icons.wifi_off_rounded,
          iconColor: hasData ? Colors.orangeAccent : Colors.redAccent,
        );
      }
    });

    if (hasData && isOnline && _justReconnected && !_hasShownSavedToast && lastError == null) {
      _hasShownSavedToast = true;
      _justReconnected = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BonoboSoftToast.showArticlesSavedLocally(context);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0E1118)
            : const Color(0xFFF2F4F7),
        body: Stack(
          children: [
            // ── Contenu défilant ───────────────────────────────────────────
            Positioned.fill(
              child: _buildBody(context, articles, heroArticles, hasData, isFirstLoad, isRefreshing, isOnline, statusBarH),
            ),

            // ── Header Transparent Overlay (Background/Gradient only) ─────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: statusBarH + 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Header Actions (Clickable) ─────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: _appBarSolid
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0E1118).withOpacity(0.98)
                          : const Color(0xFFF2F4F7).withOpacity(0.98))
                      : Colors.transparent,
                  boxShadow: _appBarSolid
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: _EditorialHeader(
                  statusBarH: statusBarH,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  onSearch: () => context.push('/search'),
                  onAccount: () => context.push('/compte'),
                  onTheme: () => ref.read(themeProvider.notifier).toggle(),
                  themeMode: ref.watch(themeProvider),
                  isSolid: _appBarSolid,
                ),
              ),
            ),

            // ── Banner Offline & Loading ───────────────────────────────────
            Positioned(
              top: statusBarH + 60, // Juste sous le logo/actions
              left: 20,
              right: 20,
              child: Column(
                children: [
                  const OfflineBanner(),
                  if (isRefreshing && hasData)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.primaryGreen,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, List<FeedNews> articles, List<FeedNews> heroArticles,
      bool hasData, bool isFirstLoad, bool isRefreshing, bool isOnline, double statusBarH) {
    final filtered = _filterArticles(articles);
    // Hero height : 42 % de la hauteur d'écran, entre 260 et 400 px
    final screenH = MediaQuery.sizeOf(ctx).height;
    final heroHeight = (screenH * 0.42).clamp(260.0, 400.0);

    if (isFirstLoad) {
      return _LoadingBody(heroHeight: heroHeight);
    }

    if (!hasData) {
      return _EmptyFirstLoad(
        isOnline: isOnline,
        lastError: ref.watch(newsLastErrorProvider),
        onRetry: () async {
          ref.read(refreshNewsProvider)();
          if (mounted) {
            final service = ref.read(connectivityServiceProvider);
            final quality = await service.checkQuality();
            final connType = ref.read(connectionTypeProvider).valueOrNull ?? 'Réseau';
            if (mounted) {
              BonoboSoftToast.showConnectionQuality(context, quality, connType);
            }
          }
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      backgroundColor: AppColors.backgroundDark,
      onRefresh: () async {
        _hasShownSavedToast = false;
        await ref.read(refreshNewsProvider)();
        if (mounted) {
          final service = ref.read(connectivityServiceProvider);
          final quality = await service.checkQuality();
          final connType = ref.read(connectionTypeProvider).valueOrNull ?? 'Réseau';
          if (mounted) {
            BonoboSoftToast.showConnectionQuality(context, quality, connType);
          }
        }
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // ── Hero slider ──────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: heroHeight,
              child: heroArticles.isNotEmpty
                  ? HeroSliderWidget(articles: heroArticles)
                  : _HeroShimmer(height: heroHeight),
            ),
          ),
          // ── Plus de Flash Ticker ici ─────────────────────
          // ── Bande "En ce moment" (Filtrée pour unicité) ────────────────
          if (filtered.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: _HorizontalArticleStrip(
                  articles: filtered
                      .where((a) => !heroArticles.any((h) => h.id == a.id))
                      .take(10)
                      .toList(),
                ),
              ),
            ),
          SliverToBoxAdapter(child: _MediaSourceSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explorer par thème', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.4, color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Filtrez l’actualité par catégorie', style: TextStyle(fontSize: 12, color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white54 : AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CategoryPills(
              selected: _selectedCategory,
              onSelect: (cat) => setState(() => _selectedCategory = cat),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aujourd\'hui', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5, color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCategory ?? 'Toute l\'actualité · Aujourd\'hui et hier',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (!isOnline) ...[
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('OFFLINE', style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyFeed(
                category: _selectedCategory,
                onClear: () => setState(() => _selectedCategory = null),
              ),
            )
          else
            ..._buildMixedLayout(filtered.length > 6 ? filtered.sublist(6) : filtered, ctx, heroHeight),
          if (!isOnline)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Vous consultez des articles en cache. Connectez-vous pour plus d\'actualités.', style: TextStyle(fontSize: 12, color: Colors.orangeAccent.withValues(alpha: 0.9), height: 1.4))),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _EmptyFirstLoad extends StatelessWidget {
  final bool isOnline;
  final String? lastError;
  final Future<void> Function() onRetry;

  const _EmptyFirstLoad({
    required this.isOnline,
    required this.onRetry,
    this.lastError,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = lastError != null;
    final icon = !isOnline
        ? Icons.wifi_off_rounded
        : hasError
            ? Icons.cloud_off_rounded
            : Icons.cloud_download_rounded;
    final title = !isOnline
        ? 'Pas de connexion internet'
        : hasError
            ? 'Impossible de charger'
            : 'Chargement en cours...';
    final subtitle = !isOnline
        ? 'Dès que la connexion sera rétablie, les actualités se chargeront automatiquement.'
        : hasError
            ? 'Nous n\'avons pas pu accéder aux sources d\'actualités. Vérifiez votre connexion et réessayez.'
            : 'Récupération des dernières actualités congolaises...';

    return Container(
      color: const Color(0xFF0E1118),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (hasError || !isOnline ? Colors.orange : AppColors.primaryGreen)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: hasError || !isOnline ? Colors.orangeAccent : AppColors.primaryGreenStart,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualiser'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────
//  Bande horizontale de 6 articles (entre slider et Média Source)
// ─────────────────────────────────────────────
class _HorizontalArticleStrip extends ConsumerWidget {
  final List<FeedNews> articles;

  const _HorizontalArticleStrip({required this.articles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesMap = ref.watch(mediaSourcesMapProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1117)
          : const Color(0xFFF2F4F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'En ce moment',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              // Largeur de carte : 44 % de l'écran, entre 130 et 180 px
              final cardW = (constraints.maxWidth * 0.44).clamp(130.0, 180.0);
              // Hauteur du strip = image (16:9) + texte (≈60px)
              final imgH = cardW * 9 / 16;
              final stripH = imgH + 62;
              return SizedBox(
                height: stripH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    final source = sourcesMap[article.sourceId];
                    final sourceColor = source?.color ?? AppColors.primaryGreen;
                    return GestureDetector(
                      onTap: () => context.push(
                        '/article/${Uri.encodeComponent(article.id)}',
                        extra: {'article': article.toJson()},
                      ),
                      child: SizedBox(
                        width: cardW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: BonoboArticleImage(
                                  imageUrl: article.imageUrl,
                                  width: cardW,
                                  height: imgH,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              article.sourceName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: sourceColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AppBar button helper
// ─────────────────────────────────────────────
class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Bouton de bascule de thème (soleil / lune / auto) dans l'AppBar.
/// Cycle : system → light → dark → system (persisté en local).
class _ThemeToggleBtn extends ConsumerWidget {
  const _ThemeToggleBtn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light  => Icons.light_mode_rounded,
      ThemeMode.dark   => Icons.dark_mode_rounded,
    };
    final label = switch (mode) {
      ThemeMode.system => 'Auto',
      ThemeMode.light  => 'Clair',
      ThemeMode.dark   => 'Sombre',
    };
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).toggle(),
      onLongPress: () => _showThemePicker(context, ref, mode),
      child: Tooltip(
        message: label,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Apparence',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choisissez le thème de l\'application',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _ThemeOption(
              icon: Icons.brightness_auto_rounded,
              label: 'Automatique',
              subtitle: 'Suit le réglage de votre téléphone',
              isSelected: current == ThemeMode.system,
              onTap: () {
                ref.read(themeProvider.notifier).setSystem();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            _ThemeOption(
              icon: Icons.light_mode_rounded,
              label: 'Mode clair',
              subtitle: 'Interface lumineuse',
              isSelected: current == ThemeMode.light,
              onTap: () {
                ref.read(themeProvider.notifier).setLight();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            _ThemeOption(
              icon: Icons.dark_mode_rounded,
              label: 'Mode sombre',
              subtitle: 'Interface sombre, économe en batterie OLED',
              isSelected: current == ThemeMode.dark,
              onTap: () {
                ref.read(themeProvider.notifier).setDark();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryGreenStart : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryGreenStart : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreenStart, size: 22),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────
//  Section Média Source — style soft, adaptatif dark/light
// ─────────────────────────────────────────────
/// Section "Nos médias partenaires" — fond immersif inspiré de l'espace journaliste.
class _MediaSourceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSources = ref.watch(dynamicMediaSourcesProvider);
    final sources = asyncSources.valueOrNull ?? [];
    return Stack(
      children: [
        // ── Fond vert uniforme — même ton que l'espace journaliste
        Positioned.fill(
          child: Container(color: const Color(0xFF01732C)),
        ),

        // ── Contenu
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Media sources',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: -0.4,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sources d\'information vérifiées',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/media-picker'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.50),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Voir tout',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Badges scrollables (toujours style sombre sur ce fond)
                  SizedBox(
                    height: 52,
                    child: asyncSources.when(
                      data: (sources) => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: sources.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => _MediaSourceBadge(
                          source: sources[i],
                          isDark: false,
                        ),
                      ),
                      loading: () => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => _MediaSourceShimmer(),
                      ),
                      error: (_, __) => const Center(
                        child: Text(
                          'Impossible de charger les sources',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),

            // ── CTA "Vous êtes un média ?"
            GestureDetector(
              onTap: () => DevenirMediaSourceModal.show(context),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.add_business_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vous êtes un média ?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Proposez votre flux et rejoignez Bonobo.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaSourceBadge extends StatelessWidget {
  final MediaSource source;
  final bool isDark;

  const _MediaSourceBadge({required this.source, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Sur fond vert uniforme : fond gris léger teinté, textes sombres
    final cardBg = isDark
        ? const Color(0xFF1C2230)
        : const Color(0xFFF2F7F3); // gris très légèrement vert
    final nameColor = isDark ? Colors.white : const Color(0xFF1A2E1E);
    final subColor = isDark
        ? const Color(0xFF8A96A8)
        : const Color(0xFF4A6550);
    final borderColor = isDark
        ? const Color(0xFF262D3D)
        : Colors.white.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: () => context.push('/media/${source.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cardBg,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaFavicon(
              faviconUrl: source.faviconUrl,
              fallbackInitials: source.initials,
              fallbackColor: source.color,
              size: 24,
              borderRadius: 6,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: nameColor,
                  ),
                ),
                Text(
                  source.countryLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Pills catégories — dynamiques depuis les articles
// ─────────────────────────────────────────────
class _CategoryPills extends ConsumerWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _CategoryPills({
    required this.selected,
    required this.onSelect,
  });

  IconData _getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('politique')) return Icons.account_balance_rounded;
    if (lower.contains('écon') || lower.contains('finance')) return Icons.trending_up_rounded;
    if (lower.contains('sport')) return Icons.sports_soccer_rounded;
    if (lower.contains('société') || lower.contains('culture')) return Icons.groups_rounded;
    if (lower.contains('inter') || lower.contains('monde')) return Icons.language_rounded;
    if (lower.contains('sécurité') || lower.contains('justice')) return Icons.shield_rounded;
    if (lower.contains('santé')) return Icons.medical_services_rounded;
    if (lower.contains('tech')) return Icons.biotech_rounded;
    if (lower.contains('éduc')) return Icons.school_rounded;
    return Icons.label_important_outline_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncCategories = ref.watch(categoriesProvider);

    return asyncCategories.when(
      data: (categories) {
        final list = [
          (null, Icons.public_rounded, 'Tout'),
          ...categories.map((c) => (c.name, _getIconForCategory(c.name), c.name)),
        ];

        return SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final cat = list[i];
              final isSelected = cat.$1 == selected;
              return GestureDetector(
                onTap: () => onSelect(cat.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF01732C), Color(0xFF025A22), Color(0xFF036027)],
                            stops: [0.0, 0.55, 1.0],
                          )
                        : null,
                    color: isSelected ? null : (isDark ? const Color(0xFF1E2535) : Colors.white),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.$2,
                        size: 16,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => _CategoryShimmer(),
      error: (_, __) => _StaticCategoryPills(selected: selected, onSelect: onSelect),
    );
  }
}

class _CategoryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 5,
        itemBuilder: (context, i) => Container(
          width: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

class _StaticCategoryPills extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _StaticCategoryPills({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _fallbackCategories.length,
        itemBuilder: (context, i) {
          final cat = _fallbackCategories[i];
          final isSelected = cat.$1 == selected;
          return GestureDetector(
            onTap: () => onSelect(cat.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : (isDark ? const Color(0xFF1E2535) : Colors.white),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(cat.$2, size: 16, color: isSelected ? Colors.white : Colors.white70),
                  const SizedBox(width: 6),
                  Text(cat.$3, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MediaSourceShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6))),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 60, height: 8, color: Colors.white12),
              const SizedBox(height: 4),
              Container(width: 40, height: 6, color: Colors.white12),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Hero shimmer loading
// ─────────────────────────────────────────────
class _HeroShimmer extends StatelessWidget {
  final double height;
  const _HeroShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_icon_white.png',
              width: 50,
              height: 50,
              opacity: const AlwaysStoppedAnimation(0.4),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreenStart.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading + Error bodies
// ─────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  final String? category;
  final VoidCallback onClear;

  const _EmptyFeed({this.category, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreenStart.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.article_outlined, size: 48, color: Colors.white38),
            ),
            const SizedBox(height: 24),
            Text(
              category != null 
                ? 'Aucun article trouvé dans "$category"'
                : 'L\'actualité se repose...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revenez plus tard pour de nouvelles informations en direct du terrain.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            if (category != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryGreenStart.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Voir tout', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  final double heroHeight;
  const _LoadingBody({required this.heroHeight});

  @override
  Widget build(BuildContext context) {
    return _HeroShimmer(height: heroHeight);
  }
}


class _JournalistBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _JournalistBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF01732C), Color(0xFF025A22), Color(0xFF036027)],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // Légère texture : points blancs en surimpression
            color: Colors.transparent,
          ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryGreenStart,
                                boxShadow: [BoxShadow(color: AppColors.primaryGreenStart.withValues(alpha: 0.6), blurRadius: 6)],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ESPACE JOURNALISTE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Votre plume\nmérite d\'être lue.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Publiez vos articles sur Bonobo.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primaryGreen, size: 26),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

Future<void> clearLocalStorage(WidgetRef ref) async {
  await ref.read(refreshNewsProvider)();
}

// ═════════════════════════════════════════════════════════════════════════════
//  _EditorialHeader — Header éditorial premium Bonobo
// ═════════════════════════════════════════════════════════════════════════════
class _EditorialHeader extends ConsumerWidget {
  final double statusBarH;
  final bool isDark;
  final VoidCallback onSearch;
  final VoidCallback onAccount;
  final VoidCallback onTheme;
  final ThemeMode themeMode;
  final bool isSolid;

  const _EditorialHeader({
    required this.statusBarH,
    required this.isDark,
    required this.onSearch,
    required this.onAccount,
    required this.onTheme,
    required this.themeMode,
    this.isSolid = false,
  });

  static final _dayNames = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  static final _monthNames = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String get _todayLabel {
    final now = DateTime.now();
    return '${_dayNames[now.weekday % 7]} ${now.day} ${_monthNames[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeIcon = switch (themeMode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light  => Icons.light_mode_rounded,
      ThemeMode.dark   => Icons.dark_mode_rounded,
    };
    final bool useDarkElements = !isDark && isSolid;
    final textColor = useDarkElements ? AppColors.textPrimary : Colors.white;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row : logo + actions ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Logo Bonobo (Icône blanche agrandie)
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/images/logo_icon_white.png',
                  height: 48,
                  fit: BoxFit.contain,
                  color: useDarkElements ? AppColors.primaryGreenStart : null,
                  errorBuilder: (_, __, ___) => Text(
                    'BONOBO',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Actions
              _HeaderBtn(icon: Icons.search_rounded, onTap: onSearch, useDarkElements: useDarkElements),
              const SizedBox(width: 6),
              _HeaderBtn(icon: themeIcon, onTap: () => ref.read(themeProvider.notifier).toggle(), useDarkElements: useDarkElements),
              const SizedBox(width: 6),
              // Account with status indicator
              _AccountHeaderBtn(onAccount: onAccount, useDarkElements: useDarkElements),
            ],
          ),
        ],
      ),
    ),
  );
}
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool useDarkElements;

  const _HeaderBtn({required this.icon, required this.onTap, this.useDarkElements = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: useDarkElements ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: useDarkElements ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.08),
              width: 0.8),
        ),
        child: Icon(icon, color: useDarkElements ? AppColors.textPrimary : Colors.white, size: 17),
      ),
    );
  }
}

class _AccountHeaderBtn extends ConsumerWidget {
  final VoidCallback onAccount;
  final bool useDarkElements;

  const _AccountHeaderBtn({required this.onAccount, required this.useDarkElements});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authProvider.select((s) => s.isAuthenticated));
    final iconColor = useDarkElements ? AppColors.textPrimary : Colors.white;
    
    return GestureDetector(
      onTap: onAccount,
      child: Stack(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: useDarkElements ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: useDarkElements ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.08),
                  width: 0.8),
            ),
            child: Icon(
              isAuthenticated ? Icons.person_rounded : Icons.person_outline_rounded,
              color: isAuthenticated ? AppColors.primaryGreenStart : iconColor,
              size: 17,
            ),
          ),
          if (isAuthenticated)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenStart,
                  shape: BoxShape.circle,
                  border: Border.all(color: useDarkElements ? Colors.white : Colors.black, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreenStart.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

