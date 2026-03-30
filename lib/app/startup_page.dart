import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/news/domain/feed_news.dart';
import '../shared/local_storage.dart';

class StartupPage extends StatefulWidget {
  final VoidCallback onComplete;
  const StartupPage({super.key, required this.onComplete});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _gridCtrl;
  late AnimationController _logoCtrl;
  
  List<String> _imageUrls = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // Initialiser les images depuis le cache local
    final articles = LocalStorage.getArticles();
    _imageUrls = articles
        .where((a) => a.imageUrl != null && a.imageUrl!.isNotEmpty)
        .map((a) => a.imageUrl!)
        .toList();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Petit délai initial pour que le moteur Flutter se pose
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Apparition du logo et du grid
    _fadeCtrl.forward();
    _logoCtrl.forward();

    // Temps d'affichage minimal (10s)
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted) return;

    // Disparition en fondu
    await _fadeCtrl.reverse();
    if (!mounted) return;

    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _gridCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0D1B12),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B12),
        body: FadeTransition(
          opacity: _fadeCtrl,
          child: Stack(
            children: [
              // ── Background: Grille penchée animée ──────────────────────────
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: AnimatedBuilder(
                    animation: _gridCtrl,
                    builder: (context, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspective
                          ..rotateX(-0.5)
                          ..rotateZ(0.4)
                          ..translate(0.0, -_gridCtrl.value * 500, 0.0),
                        child: _TiltedGrid(imageUrls: _imageUrls),
                      );
                    },
                  ),
                ),
              ),

              // ── Gradient Overlay pour la lisibilité ────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0D1B12).withOpacity(0.8),
                        const Color(0xFF0D1B12).withOpacity(0.4),
                        const Color(0xFF0D1B12),
                      ],
                      stops: const [0.0, 0.5, 0.9],
                    ),
                  ),
                ),
              ),

              // ── Branding & Loader (Groupe Bas) ──────────────────────────────
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _fadeCtrl,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                  )),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo sans coupure
                      Hero(
                        tag: 'app_logo',
                        child: SizedOverflowBox(
                          size: const Size(180, 70),
                          child: Image.asset(
                            'assets/images/logo_white.png',
                            width: 180,
                            height: 70,
                            fit: BoxFit.contain, // Visible en entier
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.newspaper_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Tagline mise à jour pour l'expansion Afrique
                      Text(
                        "L'actualité dans un seul endroit",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Nouveau Loader Arc Premium
                      const _BonoboArcLoader(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TiltedGrid extends StatelessWidget {
  final List<String> imageUrls;
  const _TiltedGrid({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    // On crée une grille infinie (répétée) pour l'effet de scroll
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        if (imageUrls.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }
        
        final url = imageUrls[index % imageUrls.length];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.white10),
            errorWidget: (_, __, ___) => Container(color: Colors.white10),
          ),
        );
      },
    );
  }
}

class _BonoboArcLoader extends StatefulWidget {
  const _BonoboArcLoader();

  @override
  State<_BonoboArcLoader> createState() => _BonoboArcLoaderState();
}

class _BonoboArcLoaderState extends State<_BonoboArcLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Transform.rotate(
          angle: _c.value * 2 * math.pi,
          child: CustomPaint(
            size: const Size(28, 28),
            painter: _ArcPainter(color: const Color(0xFF1EB45A)),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // On dessine un arc de 270 degrés
    canvas.drawArc(rect, 0, 4.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
