import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 18,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: AppColors.textPrimary,
      );
}
