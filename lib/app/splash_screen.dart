import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../features/news/providers/news_providers.dart';
import '../features/news/domain/media_source.dart';

import '../core/constants/app_colors.dart';

/// Splash screen Bonobo.
/// Flux : fond sombre apparaît instantanément → logo entre (grand → normal, elastic) →
///        sous-titre fade in → barre de chargement animée → fondu en blanc/noir vers l'accueil.
///
/// Le splash natif Android utilise drawable/background.png (fond sombre uniforme).
/// Il n'y a aucun écran blanc intermédiaire.
class BonoboSplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const BonoboSplashScreen({super.key, required this.onComplete});

  @override
  ConsumerState<BonoboSplashScreen> createState() => _BonoboSplashScreenState();
}

class _BonoboSplashScreenState extends ConsumerState<BonoboSplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _entryController;   // logo entry
  late AnimationController _pulseController;   // halo pulse loop
  late AnimationController _barController;     // progress bar
  late AnimationController _exitController;    // fade out
  late AnimationController _mediaController;   // scrolling media

  // ── Animations ────────────────────────────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _pulseOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _barProgress;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // ── Entry (logo grand → normal) ─────────────────────
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 2.2, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Halo pulse ──────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.18, end: 0.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Barre de chargement (500ms → pleine en 1.5s) ────
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );

    // ── Exit (fondu) ─────────────────────────────────────
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
    );

    // ── Media Scrolling ──────────────────────────────────
    _mediaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // ── Séquence ─────────────────────────────────────────
    _start();
  }

  Future<void> _start() async {
    await _entryController.forward();
    _barController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _barController.dispose();
    _exitController.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: child,
          );
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0D1B12),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [
                  Color(0xFF0F2E1A),
                  Color(0xFF0A1810),
                  Color(0xFF060E0A),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [

                // ── Halo vert animé ──────────────────────────────────────
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseScale.value,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreenStart
                                  .withValues(alpha: _pulseOpacity.value),
                              blurRadius: 120,
                              spreadRadius: 50,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ── Logo (grand → normal, elastic) ───────────────────────
                AnimatedBuilder(
                  animation: _entryController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    width: 320,
                    height: 110,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const _FallbackLogo(),
                  ),
                ),

                // ── Sous-titre + barre de chargement ─────────────────────
                Positioned(
                  bottom: 72,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _subtitleOpacity.value,
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        // Dynamic Media Marquee
                        _buildMediaMarquee(),
                        const SizedBox(height: 32),
                        const Text(
                          "L'Actualité Congolaise Autrement",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Toute l'info de vos médias préférés en un seul endroit",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Barre de progression nette
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60),
                          child: AnimatedBuilder(
                            animation: _barController,
                            builder: (context, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _barProgress.value,
                                  minHeight: 2,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGreenStart
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaMarquee() {
    final sources = ref.watch(dynamicMediaSourcesProvider).valueOrNull ?? [];
    if (sources.isEmpty) return const SizedBox(height: 44);

    // On double ou triple la liste pour le scroll infini sans accroc
    final scrollingList = [...sources, ...sources, ...sources];

    return SizedBox(
      height: 44,
      child: AnimatedBuilder(
        animation: _mediaController,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // On définit une largeur par item
              const double itemWidth = 80.0;
              final double totalWidth = scrollingList.length * itemWidth;
              // Le décalage dépend de la progression de l'animation
              final double offset = _mediaController.value * (totalWidth / 3);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Transform.translate(
                    offset: Offset(-offset, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: scrollingList.map((s) {
                        return Container(
                          width: itemWidth,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: 0.6,
                            child: _buildMediaIcon(s),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMediaIcon(MediaSource source) {
    if (source.logoUrl.isNotEmpty && source.logoUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source.logoUrl,
        height: 28,
        fit: BoxFit.contain,
        placeholder: (_, __) => _initialsIcon(source),
        errorWidget: (_, __, ___) => _initialsIcon(source),
      );
    }
    return _initialsIcon(source);
  }

  Widget _initialsIcon(MediaSource source) {
    return Center(
      child: Text(
        source.initials,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.newspaper_rounded, size: 56, color: Colors.white38),
        SizedBox(height: 10),
        Text(
          'BONOBO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }
}
