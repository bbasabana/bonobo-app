import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/bonobo_soft_toast.dart';
import '../providers/marketing_provider.dart';
import '../providers/auth_provider.dart';
import 'marketing_promo_modal.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with TickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _anim;

  static const _items = [
    ('/', Icons.home_rounded, 'Accueil'),
    ('/categories', Icons.explore_rounded, 'Explorer'),
    ('/sports', Icons.sports_soccer_rounded, 'Sport'),
    ('/jobs', Icons.work_rounded, 'Emplois'),
    ('/journalist', Icons.edit_note_rounded, 'Journaliste'),
    ('/about', Icons.info_rounded, 'Bonobo'),
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _currentPath => GoRouterState.of(context).uri.path;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _anim.forward() : _anim.reverse();
    });
  }

  void _onMainTap() {
    if (_expanded) {
      _toggle();
    } else if (_currentPath == '/') {
      _toggle();
    } else {
      _navigate('/');
    }
  }

  void _navigate(String path) {
    if (path == '/journalist') {
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) {
        context.go('/compte');
        BonoboSoftToast.show(context,
            message: 'Connectez-vous pour accéder à l\'espace journaliste.',
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primaryGreenStart);
        return;
      }
    }
    context.go(path);
    if (_expanded) {
      setState(() => _expanded = false);
      _anim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _currentPath;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final marketing = ref.watch(marketingProvider);

    return Stack(
      children: [
        widget.child,
        if (_expanded)
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black54),
          ),
        
        // --- Marketing Modal Overlay ---
        if (marketing.showPromo && marketing.activePromo != null)
          Stack(
            children: [
              GestureDetector(
                onTap: () => ref.read(marketingProvider.notifier).dismissPromo(false),
                child: Container(color: Colors.black45),
              ),
              MarketingPromoModal(type: marketing.activePromo!),
            ],
          ),

        Positioned(
          right: 20,
          bottom: 24 + bottomPad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ..._buildExpandedItems(path),
              const SizedBox(height: 12),
              _buildMainFab(path),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExpandedItems(String path) {
    if (!_expanded) return [];
    final secondary = _items.sublist(1);
    return List.generate(secondary.length, (i) {
      final item = secondary[secondary.length - 1 - i];
      final isSelected = path == item.$1;
      final delay = (secondary.length - 1 - i) / secondary.length;
      return AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final curved = Curves.easeOutCubic.transform(
            (_anim.value - delay * 0.3).clamp(0.0, 1.0) / (1 - delay * 0.3).clamp(0.01, 1.0),
          );
          return Transform.translate(
            offset: Offset(0, 20 * (1 - curved)),
            child: Opacity(
              opacity: curved.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _navigate(item.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.backgroundDark.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$2, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    item.$3,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMainFab(String path) {
    final isHome = path == '/';
    
    return GestureDetector(
      onTap: _onMainTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4ADE80), Color(0xFF01732C), Color(0xFF036027)],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF01732C).withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: child.key == const ValueKey('close') 
                ? Tween<double>(begin: 0.75, end: 1.0).animate(anim)
                : Tween<double>(begin: 0.9, end: 1.0).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            _expanded 
                ? Icons.close_rounded 
                : (isHome ? Icons.menu_rounded : Icons.home_rounded),
            key: ValueKey(_expanded ? 'close' : (isHome ? 'menu' : 'home')),
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
