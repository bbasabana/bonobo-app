import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class TimeTabBar extends StatelessWidget {
  final TimeGroup selected;
  final ValueChanged<TimeGroup> onChanged;

  const TimeTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _groups = [
    TimeGroup.lessThanOneHour,
    TimeGroup.oneToFourHours,
    TimeGroup.fourToEightHours,
    TimeGroup.eightHoursToTenDays,
    TimeGroup.all,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final isSelected = group == selected;

          return GestureDetector(
            onTap: () => onChanged(group),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : isDark
                        ? const Color(0xFF2A2B40)
                        : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : isDark
                          ? Colors.white12
                          : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                group.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? Colors.white60
                          : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
