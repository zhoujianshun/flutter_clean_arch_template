import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

/// Application color palette
///
/// Customize these to match your brand. Uses Material 3 conventions.
class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF6750A4);
  static const Color primary50 = Color(0xFFF3EEFF);
  static const Color primary500 = primary;
  static const Color primary700 = Color(0xFF4F378B);

  // Functional colors
  static const Color success50 = Color(0xFFE8F5E8);
  static const Color success500 = Color(0xFF4CAF50);
  static const Color success700 = Color(0xFF388E3C);

  static const Color warning50 = Color(0xFFFFF3E0);
  static const Color warning500 = Color(0xFFFF9800);
  static const Color warning700 = Color(0xFFF57C00);

  static const Color error50 = Color(0xFFFFEBEE);
  static const Color error500 = Color(0xFFF44336);
  static const Color error700 = Color(0xFFD32F2F);

  static const Color info50 = Color(0xFFE3F2FD);
  static const Color info500 = Color(0xFF2196F3);
  static const Color info700 = Color(0xFF1976D2);

  // Neutral colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textDisabled = Color(0xFFCCCCCC);

  // Background
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundTertiary = Color(0xFFF0F0F0);

  // Border & Divider
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);
}

/// Application theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.backgroundSecondary,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: ResponsiveTokens.font(17, medium: 17, expanded: 17),
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveTokens.size(12, medium: 12, expanded: 12),
          ),
        ),
        color: AppColors.backgroundPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(
            double.infinity,
            ResponsiveTokens.size(48, medium: 48, expanded: 48),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveTokens.size(12, medium: 12, expanded: 12),
            ),
          ),
          textStyle: TextStyle(
            fontSize: ResponsiveTokens.font(16, medium: 16, expanded: 16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveTokens.size(12, medium: 12, expanded: 12),
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveTokens.size(12, medium: 12, expanded: 12),
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveTokens.size(12, medium: 12, expanded: 12),
          ),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveTokens.size(16, medium: 16, expanded: 16),
          vertical: ResponsiveTokens.size(14, medium: 14, expanded: 14),
        ),
        hintStyle: TextStyle(
          color: AppColors.textHint,
          fontSize: ResponsiveTokens.font(14, medium: 14, expanded: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: AppColors.backgroundPrimary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.neutral500,
        selectedLabelStyle: TextStyle(
          fontSize: ResponsiveTokens.font(11, medium: 11, expanded: 11),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ResponsiveTokens.font(11, medium: 11, expanded: 11),
        ),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveTokens.font(17, medium: 17, expanded: 17),
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}

/// Dark/light mode adaptive color utilities.
///
/// Provides context-aware colors that automatically adapt to the current theme.
class AppAdaptiveColors {
  AppAdaptiveColors._();

  static bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Brand
  static Color primary(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF9B8CC7) : AppColors.primary;
  static Color primary50(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF2D2640) : AppColors.primary50;
  static Color primary500(BuildContext context) => primary(context);
  static Color primary700(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFB39DDB) : AppColors.primary700;

  // Functional
  static Color success50(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF1B3D1B) : AppColors.success50;
  static Color success500(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF66BB6A) : AppColors.success500;
  static Color warning50(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF3D2E00) : AppColors.warning50;
  static Color warning500(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFFFB74D) : AppColors.warning500;
  static Color error50(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF3D1B1B) : AppColors.error50;
  static Color error500(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFEF5350) : AppColors.error500;

  // Neutral scale
  static Color neutral50(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF303030) : AppColors.neutral50;
  static Color neutral100(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF2A2A2A) : AppColors.neutral100;
  static Color neutral150(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF282828) : const Color(0xFFF0F0F0);
  static Color neutral200(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF252525) : AppColors.neutral200;
  static Color neutral300(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF333333) : AppColors.neutral300;
  static Color neutral400(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF555555) : AppColors.neutral400;
  static Color neutral500(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF888888) : AppColors.neutral500;
  static Color neutral600(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFAAAAAA) : AppColors.neutral600;
  static Color neutral650(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFBBBBBB) : const Color(0xFF6B6B6B);
  static Color neutral700(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFCCCCCC) : AppColors.neutral700;
  static Color neutral750(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFDDDDDD) : const Color(0xFF555555);
  static Color neutral800(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFE0E0E0) : AppColors.neutral800;
  static Color neutral900(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFF0F0F0) : AppColors.neutral900;

  // Text
  static Color textPrimary(BuildContext context) =>
      _isDarkMode(context) ? Colors.white : AppColors.textPrimary;
  static Color textSecondary(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFAAAAAA) : AppColors.textSecondary;
  static Color textHint(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF777777) : AppColors.textHint;
  static Color textDisabled(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF555555) : AppColors.textDisabled;

  // Background
  static Color backgroundPrimary(BuildContext context) => _isDarkMode(context)
      ? const Color(0xFF1E1E1E)
      : AppColors.backgroundPrimary;
  static Color backgroundSecondary(BuildContext context) => _isDarkMode(context)
      ? const Color(0xFF121212)
      : AppColors.backgroundSecondary;

  // Surface
  static Color surface(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF1E1E1E) : Colors.white;

  // Functional extended
  static Color error700(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFFEF5350) : AppColors.error700;

  // Border & Divider
  static Color border(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF333333) : AppColors.border;
  static Color divider(BuildContext context) =>
      _isDarkMode(context) ? const Color(0xFF2A2A2A) : AppColors.divider;
}

/// Pre-defined text styles for consistent typography.
/// Pre-defined spacing constants
class AppSpacing {
  AppSpacing._();
  static double get xs => ResponsiveTokens.size(4, medium: 4, expanded: 4);
  static double get sm => ResponsiveTokens.size(8, medium: 8, expanded: 8);
  static double get md => ResponsiveTokens.size(12, medium: 12, expanded: 12);
  static double get lg => ResponsiveTokens.size(16, medium: 16, expanded: 16);
  static double get xl => ResponsiveTokens.size(24, medium: 24, expanded: 24);
  static double get xxl => ResponsiveTokens.size(32, medium: 32, expanded: 32);
}

/// Pre-defined border radius constants
class AppBorderRadius {
  AppBorderRadius._();
  static BorderRadius get xs =>
      BorderRadius.circular(ResponsiveTokens.size(4, medium: 4, expanded: 4));
  static BorderRadius get sm =>
      BorderRadius.circular(ResponsiveTokens.size(8, medium: 8, expanded: 8));
  static BorderRadius get md => BorderRadius.circular(
    ResponsiveTokens.size(12, medium: 12, expanded: 12),
  );
  static BorderRadius get lg => BorderRadius.circular(
    ResponsiveTokens.size(16, medium: 16, expanded: 16),
  );
  static BorderRadius get xl => BorderRadius.circular(
    ResponsiveTokens.size(24, medium: 24, expanded: 24),
  );
  static BorderRadius get full => BorderRadius.circular(
    ResponsiveTokens.size(999, medium: 999, expanded: 999),
  );
}

/// Pre-defined text styles for consistent typography.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamilyMedium = '';
  static const String fontFamilyRegular = '';

  static TextStyle get h1 => TextStyle(
    fontSize: ResponsiveTokens.font(32, medium: 32, expanded: 32),
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => TextStyle(
    fontSize: ResponsiveTokens.font(28, medium: 28, expanded: 28),
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.25,
  );

  static TextStyle get h3 => TextStyle(
    fontSize: ResponsiveTokens.font(24, medium: 24, expanded: 24),
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  static TextStyle get h4 => TextStyle(
    fontSize: ResponsiveTokens.font(20, medium: 20, expanded: 20),
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  static TextStyle get h5 => TextStyle(
    fontSize: ResponsiveTokens.font(18, medium: 18, expanded: 18),
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle get h6 => TextStyle(
    fontSize: ResponsiveTokens.font(16, medium: 16, expanded: 16),
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: ResponsiveTokens.font(18, medium: 18, expanded: 18),
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: ResponsiveTokens.font(16, medium: 16, expanded: 16),
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: ResponsiveTokens.font(14, medium: 14, expanded: 14),
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyXSmall => TextStyle(
    fontSize: ResponsiveTokens.font(12, medium: 12, expanded: 12),
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get caption => TextStyle(
    fontSize: ResponsiveTokens.font(11, medium: 11, expanded: 11),
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get labelLarge => TextStyle(
    fontSize: ResponsiveTokens.font(14, medium: 14, expanded: 14),
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => TextStyle(
    fontSize: ResponsiveTokens.font(12, medium: 12, expanded: 12),
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: ResponsiveTokens.font(10, medium: 10, expanded: 10),
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static TextStyle get overline => TextStyle(
    fontSize: ResponsiveTokens.font(10, medium: 10, expanded: 10),
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 1.5,
  );

  static TextStyle get elderlyBodyLarge => TextStyle(
    fontSize: ResponsiveTokens.font(20, medium: 20, expanded: 20),
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
