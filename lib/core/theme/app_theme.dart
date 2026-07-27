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
  static const Color neutral650 = Color(0xFF6B6B6B);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral750 = Color(0xFF555555);
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
  static const Color surface = backgroundPrimary;

  // Extended neutral colors
  static const Color neutral150 = backgroundTertiary;

  // Border & Divider
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);
}

/// Dark mode color palette.
///
/// Keeping dark tokens in one place avoids scattering hard-coded colors
/// across theme and adaptive color utilities.
class AppDarkColors {
  AppDarkColors._();

  // Brand colors
  static const Color primary = Color(0xFF9B8CC7);
  static const Color primary50 = Color(0xFF2D2640);
  static const Color primary500 = primary;
  static const Color primary700 = Color(0xFFB39DDB);

  // Functional colors
  static const Color success50 = Color(0xFF1B3D1B);
  static const Color success500 = Color(0xFF66BB6A);

  static const Color warning50 = Color(0xFF3D2E00);
  static const Color warning500 = Color(0xFFFFB74D);

  static const Color error50 = Color(0xFF3D1B1B);
  static const Color error500 = Color(0xFFEF5350);
  static const Color error700 = error500;

  // Neutral colors
  static const Color neutral50 = Color(0xFF303030);
  static const Color neutral100 = Color(0xFF2A2A2A);
  static const Color neutral150 = Color(0xFF282828);
  static const Color neutral200 = Color(0xFF252525);
  static const Color neutral300 = Color(0xFF333333);
  static const Color neutral400 = Color(0xFF555555);
  static const Color neutral500 = Color(0xFF888888);
  static const Color neutral600 = Color(0xFFAAAAAA);
  static const Color neutral650 = Color(0xFFBBBBBB);
  static const Color neutral700 = Color(0xFFCCCCCC);
  static const Color neutral750 = Color(0xFFDDDDDD);
  static const Color neutral800 = Color(0xFFE0E0E0);
  static const Color neutral900 = Color(0xFFF0F0F0);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textHint = Color(0xFF777777);
  static const Color textDisabled = Color(0xFF555555);

  // Background
  static const Color backgroundPrimary = Color(0xFF1E1E1E);
  static const Color backgroundSecondary = Color(0xFF121212);
  static const Color surface = backgroundPrimary;

  // Border & Divider
  static const Color border = Color(0xFF333333);
  static const Color divider = Color(0xFF2A2A2A);
}

/// Application theme configuration
class AppTheme {
  AppTheme._();

  /// Unified light color scheme sourced from app design tokens.
  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
      ).copyWith(
        primary: AppColors.primary,
        primaryContainer: AppColors.primary50,
        onPrimaryContainer: AppColors.primary700,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error500,
        outline: AppColors.border,
      );

  /// Unified dark color scheme sourced from app design tokens.
  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppDarkColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppDarkColors.primary,
        primaryContainer: AppDarkColors.primary50,
        onPrimaryContainer: AppDarkColors.primary700,
        surface: AppDarkColors.surface,
        onSurface: AppDarkColors.textPrimary,
        error: AppDarkColors.error500,
        outline: AppDarkColors.border,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
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
            0,
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
        selectedItemColor: _lightColorScheme.primary,
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
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppDarkColors.backgroundSecondary,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: AppDarkColors.backgroundPrimary,
        foregroundColor: AppDarkColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: ResponsiveTokens.font(17, medium: 17, expanded: 17),
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveTokens.size(12, medium: 12, expanded: 12),
          ),
        ),
        color: AppDarkColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(
            0,
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
        fillColor: AppDarkColors.neutral100,
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
          borderSide: const BorderSide(color: AppDarkColors.primary),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveTokens.size(16, medium: 16, expanded: 16),
          vertical: ResponsiveTokens.size(14, medium: 14, expanded: 14),
        ),
        hintStyle: TextStyle(
          color: AppDarkColors.textHint,
          fontSize: ResponsiveTokens.font(14, medium: 14, expanded: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppDarkColors.divider,
        thickness: 0.5,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: AppDarkColors.backgroundPrimary,
        selectedItemColor: _darkColorScheme.primary,
        unselectedItemColor: AppDarkColors.neutral500,
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
}

/// Dark/light mode adaptive color utilities.
///
/// Provides context-aware colors that automatically adapt to the current theme.
class AppAdaptiveColors {
  AppAdaptiveColors._();

  static bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color _resolve(BuildContext context, Color light, Color dark) =>
      _isDarkMode(context) ? dark : light;

  // Brand
  static Color primary(BuildContext context) =>
      _resolve(context, AppColors.primary, AppDarkColors.primary);
  static Color primary50(BuildContext context) =>
      _resolve(context, AppColors.primary50, AppDarkColors.primary50);
  static Color primary500(BuildContext context) => primary(context);
  static Color primary700(BuildContext context) =>
      _resolve(context, AppColors.primary700, AppDarkColors.primary700);

  // Functional
  static Color success50(BuildContext context) =>
      _resolve(context, AppColors.success50, AppDarkColors.success50);
  static Color success500(BuildContext context) =>
      _resolve(context, AppColors.success500, AppDarkColors.success500);
  static Color warning50(BuildContext context) =>
      _resolve(context, AppColors.warning50, AppDarkColors.warning50);
  static Color warning500(BuildContext context) =>
      _resolve(context, AppColors.warning500, AppDarkColors.warning500);
  static Color error50(BuildContext context) =>
      _resolve(context, AppColors.error50, AppDarkColors.error50);
  static Color error500(BuildContext context) =>
      _resolve(context, AppColors.error500, AppDarkColors.error500);

  // Neutral scale
  static Color neutral50(BuildContext context) =>
      _resolve(context, AppColors.neutral50, AppDarkColors.neutral50);
  static Color neutral100(BuildContext context) =>
      _resolve(context, AppColors.neutral100, AppDarkColors.neutral100);
  static Color neutral150(BuildContext context) =>
      _resolve(context, AppColors.neutral150, AppDarkColors.neutral150);
  static Color neutral200(BuildContext context) =>
      _resolve(context, AppColors.neutral200, AppDarkColors.neutral200);
  static Color neutral300(BuildContext context) =>
      _resolve(context, AppColors.neutral300, AppDarkColors.neutral300);
  static Color neutral400(BuildContext context) =>
      _resolve(context, AppColors.neutral400, AppDarkColors.neutral400);
  static Color neutral500(BuildContext context) =>
      _resolve(context, AppColors.neutral500, AppDarkColors.neutral500);
  static Color neutral600(BuildContext context) =>
      _resolve(context, AppColors.neutral600, AppDarkColors.neutral600);
  static Color neutral650(BuildContext context) =>
      _resolve(context, AppColors.neutral650, AppDarkColors.neutral650);
  static Color neutral700(BuildContext context) =>
      _resolve(context, AppColors.neutral700, AppDarkColors.neutral700);
  static Color neutral750(BuildContext context) =>
      _resolve(context, AppColors.neutral750, AppDarkColors.neutral750);
  static Color neutral800(BuildContext context) =>
      _resolve(context, AppColors.neutral800, AppDarkColors.neutral800);
  static Color neutral900(BuildContext context) =>
      _resolve(context, AppColors.neutral900, AppDarkColors.neutral900);

  // Text
  static Color textPrimary(BuildContext context) =>
      _resolve(context, AppColors.textPrimary, AppDarkColors.textPrimary);
  static Color textSecondary(BuildContext context) =>
      _resolve(context, AppColors.textSecondary, AppDarkColors.textSecondary);
  static Color textHint(BuildContext context) =>
      _resolve(context, AppColors.textHint, AppDarkColors.textHint);
  static Color textDisabled(BuildContext context) =>
      _resolve(context, AppColors.textDisabled, AppDarkColors.textDisabled);

  // Background
  static Color backgroundPrimary(BuildContext context) => _resolve(
    context,
    AppColors.backgroundPrimary,
    AppDarkColors.backgroundPrimary,
  );
  static Color backgroundSecondary(BuildContext context) => _resolve(
    context,
    AppColors.backgroundSecondary,
    AppDarkColors.backgroundSecondary,
  );

  // Surface
  static Color surface(BuildContext context) =>
      _resolve(context, AppColors.surface, AppDarkColors.surface);

  // Functional extended
  static Color error700(BuildContext context) =>
      _resolve(context, AppColors.error700, AppDarkColors.error700);

  // Border & Divider
  static Color border(BuildContext context) =>
      _resolve(context, AppColors.border, AppDarkColors.border);
  static Color divider(BuildContext context) =>
      _resolve(context, AppColors.divider, AppDarkColors.divider);
}

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

  // Keep null to use the system font unless custom families are configured.
  static const String? fontFamilyMedium = null;
  static const String? fontFamilyRegular = null;

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
