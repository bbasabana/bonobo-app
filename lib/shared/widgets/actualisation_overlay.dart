import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Petit message discret « Nous actualisons la rubrique » affiché toutes les 10s sur le slider.
class ActualisationOverlay extends StatefulWidget {
  final VoidCallback? onDismiss;
  final Duration showInterval;
  final Duration displayDuration;

  const ActualisationOverlay({
    super.key,
    this.onDismiss,
    this.showInterval = const Duration(seconds: 10),
    this.displayDuration = const Duration(milliseconds: 2500),
  });

  @override
  State<ActualisationOverlay> createState() => _ActualisationOverlayState();
}

class _ActualisationOverlayState extends State<ActualisationOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _intervalTimer;
  bool _visible = false;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _intervalTimer = Timer.periodic(widget.showInterval, (_) {
      if (!mounted) return;
      _show();
    });
  }

  void _show() {
    if (_visible) return;
    setState(() => _visible = true);
    _anim.forward(from: 0);
    Future.delayed(widget.displayDuration, () {
      if (!mounted) return;
      _anim.reverse().then((_) {
        if (mounted) {
          setState(() => _visible = false);
          widget.onDismiss?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _intervalTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 22,
                    color: AppColors.primaryGreenStart,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nous actualisons la rubrique',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
