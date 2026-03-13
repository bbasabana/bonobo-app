import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/media_sources.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/actualisation_overlay.dart';
import '../../../../shared/widgets/bonobo_article_image.dart';
import '../../domain/feed_news.dart';

class HeroSliderWidget extends StatefulWidget {
  final List<FeedNews> articles;

  const HeroSliderWidget({super.key, required this.articles});

  @override
  State<HeroSliderWidget> createState() => _HeroSliderWidgetState();
}

class _HeroSliderWidgetState extends State<HeroSliderWidget> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(AppConstants.heroAutoScrollInterval, (_) {
      if (!mounted || widget.articles.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.articles.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // Slides
        PageView.builder(
          controller: _controller,
          itemCount: widget.articles.length,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, index) => _HeroSlide(article: widget.articles[index]),
        ),
        
        // Message « Nous actualisons » toutes les 10s
        Positioned.fill(
          child: ActualisationOverlay(
            showInterval: const Duration(seconds: 10),
            displayDuration: const Duration(milliseconds: 2500),
          ),
        ),
        // Progress Indicators at bottom
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Row(
            children: [
              // Dynamic dots
              ...List.generate(widget.articles.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.only(right: 6),
                  width: isActive ? 28 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive
                        ? AppColors.primaryGreenStart
                        : Colors.white.withValues(alpha: 0.3),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: AppColors.primaryGreenStart.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                );
              }),
              const Spacer(),
              // Page count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.articles.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final FeedNews article;

  const _HeroSlide({required this.article});

  @override
  Widget build(BuildContext context) {
    final source = MediaSources.findById(article.sourceId);
    final sourceColor = source?.color ?? AppColors.primaryGreen;

    return GestureDetector(
      onTap: () => context.push(
        '/article/${Uri.encodeComponent(article.id)}',
        extra: {'article': article.toJson()},
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          _HeroBackground(imageUrl: article.imageUrl),

          // Multi-layer contrast gradients
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.2, 0.5, 1.0],
              ),
            ),
          ),
          
          // Subtle color tint at bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    sourceColor.withValues(alpha: 0.15),
                  ],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 48,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag + Category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sourceColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: sourceColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Text(
                        article.sourceName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (article.category != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '#${article.category!.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                // Title
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Time
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primaryGreenStart),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.relative(article.publishedAt).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white60,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final String? imageUrl;

  const _HeroBackground({this.imageUrl});

  static const _placeholderAsset = 'assets/images/bonobo_load_bg.jpg';

  @override
  Widget build(BuildContext context) {
    return Container(
      foregroundDecoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
      ),
      child: (imageUrl == null || imageUrl!.trim().isEmpty)
          ? Image.asset(_placeholderAsset, fit: BoxFit.cover)
          : BonoboArticleImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }
}
