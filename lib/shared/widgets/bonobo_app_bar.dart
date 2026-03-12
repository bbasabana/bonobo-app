import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BonoboAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const BonoboAppBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.actions,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      leading: leading,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_icon_white.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: const Icon(Icons.newspaper_rounded, color: Colors.white54, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Bonobo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
          : title != null
              ? Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: AppColors.white,
                  ),
                )
              : null,
      actions: actions,
      bottom: bottom,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
