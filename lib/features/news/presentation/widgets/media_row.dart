import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/news_providers.dart';
import '../../domain/media_source.dart';

class MediaRow extends ConsumerWidget {
  const MediaRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(dynamicMediaSourcesProvider).when(
      data: (sources) {
        if (sources.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Médias',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/media-picker'),
                    child: const Text(
                      'Choisir mes médias',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: sources.length,
                itemBuilder: (context, index) {
                  final source = sources[index];
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return _MediaChip(source: source, isDark: isDark);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MediaChip extends StatelessWidget {
  final MediaSource source;
  final bool isDark;

  const _MediaChip({required this.source, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/media/${source.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E2035), AppColors.backgroundDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      source.name.substring(0, source.name.length.clamp(0, 2)).toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primaryGreenStart,
                      ),
                    ),
                  ),
                ),
                if (source.certificationIcon != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        source.certificationIcon,
                        color: source.certificationColor,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 62,
              child: Text(
                source.name,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
