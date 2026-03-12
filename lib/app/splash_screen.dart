import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

/// Splash screen Bonobo : le logo commence grand (1.5x) et se réduit à sa taille normale.
/// Le splash natif (flutter_native_splash) affiche seulement un fond sombre — pas de logo.
class BonoboSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const BonoboSplashScreen({super.key, required this.onComplete});

  @override
  State<BonoboSplashScreen> createState() => _BonoboSplashScreenState();
}

class _BonoboSplashScreenState extends State<BonoboSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // Main controller: logo entry (large to small)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Subtle pulse loop
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Exit controller
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Initial scale: logo starts at 2.5x and reduces to 1.0 with elasticity
    _logoScale = Tween<double>(begin: 2.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    // Logo appears instantly or very fast
    _logoOpacity = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Subtitle fade in
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Pulse halo
    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Exit: zoom out and fade
    _exitScale = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _mainController.forward().then((_) {
      // Reduce stay delay for faster app entry
      Future<void>.delayed(const Duration(milliseconds: 1000), () async {
        if (!mounted) return;
        await _exitController.forward();
        if (!mounted) return;
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B12),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF0F2A1A),
                Color(0xFF0A1810),
                Color(0xFF060E0A),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo vert pulsé
              AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _exitController]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _exitOpacity.value * 0.6,
                    child: Transform.scale(
                      scale: _pulseScale.value,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.25),
                              blurRadius: 100,
                              spreadRadius: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Logo principal (grand → normal)
              AnimatedBuilder(
                animation: Listenable.merge([_mainController, _exitController]),
                builder: (context, child) {
                  final scale = _exitController.isAnimating
                      ? _exitScale.value
                      : _logoScale.value;
                  final opacity = _exitController.isAnimating
                      ? _exitOpacity.value
                      : _logoOpacity.value;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        'assets/images/logo_white.png',
                        width: 280,
                        height: 100,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => _FallbackLogo(),
                      ),
                    ),
                  );
                },
              ),

              // Sous-titre
              Positioned(
                bottom: 100,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_mainController, _exitController]),
                  builder: (context, child) {
                    final opacity = _exitController.isAnimating
                        ? _exitOpacity.value
                        : _subtitleOpacity.value;
                    return Opacity(
                      opacity: opacity * 0.7,
                      child: child,
                    );
                  },
                  child: const Column(
                    children: [
                      Text(
                        "L'actualité congolaise en un seul endroit",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Indicateur de chargement subtil en bas
              Positioned(
                bottom: 60,
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _subtitleOpacity.value * 0.5,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 40,
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreenStart.withValues(alpha: 0.8),
                      ),
                    ),
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

class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.newspaper_rounded, size: 60, color: Colors.white38),
        SizedBox(height: 12),
        Text(
          'BONOBO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
