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
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Decorative Element
                    Container(
                      height: 8,
                      width: 60,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                      child: Column(
                        children: [
                          // Icon Header with entrance animation
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: AppColors.primaryGradient.colors.map((c) => c.withOpacity(0.1)).toList(),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isJournalist ? Icons.newspaper_rounded : Icons.rocket_launch_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 45,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Title - Premium Typography
                          Text(
                            isJournalist ? 'VALORISEZ VOTRE PLUME' : 'BOOSTEZ VOTRE MÉDIA',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtitle
                          Text(
                            isJournalist
                                ? 'Rejoignez la révolution de l\'information indépendante. Créez votre compte, publiez vos articles et soyez lu par des milliers de congolais.'
                                : 'Augmentez votre trafic, vos revenus Adsense et votre référencement en intégrant votre flux sur Bonobo, le plus gros agrégateur.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // CTA Button - Large & Premium
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                _close(false);
                                context.push('/journalist');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Rejoindre l\'aventure',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Secondary actions - Better spacing
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => _close(false),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Plus tard',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                              TextButton(
                                onPressed: () => _close(true),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Ne plus afficher',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
