import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../providers/marketing_provider.dart';

class MarketingPromoModal extends ConsumerStatefulWidget {
  final MarketingPromoType type;

  const MarketingPromoModal({super.key, required this.type});

  @override
  ConsumerState<MarketingPromoModal> createState() => _MarketingPromoModalState();
}

class _MarketingPromoModalState extends ConsumerState<MarketingPromoModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close(bool permanent) {
    _controller.reverse().then((_) {
      ref.read(marketingProvider.notifier).dismissPromo(permanent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isJournalist = widget.type == MarketingPromoType.journalist;

    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreenStart.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isJournalist ? Icons.edit_note_rounded : Icons.hub_rounded,
                    color: AppColors.primaryGreenStart,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title - Steve Jobs style
                Text(
                  isJournalist ? 'VALORISEZ VOTRE PLUME' : 'BOOSTEZ VOTRE AUDIANCE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  isJournalist
                      ? 'Rejoignez la révolution de l\'information indépendante. Créez votre compte, publiez vos articles et soyez lu par des milliers de congolais.'
                      : 'Vous êtes un média ? Augmentez votre trafic, vos revenus Adsense et votre référencement en intégrant votre flux sur Bonobo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _close(false);
                      context.go('/journalist');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreenStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Rejoindre l\'aventure',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _close(false),
                      child: Text(
                        'Rappeler plus tard',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _close(true),
                      child: Text(
                        'Ne plus afficher',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
