import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _pumpThemeHost(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  late BuildContext capturedContext;

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();

  return capturedContext;
}

void main() {
  group('AppTheme', () {
    testWidgets('should map light color scheme from light tokens', (
      tester,
    ) async {
      final context = await _pumpThemeHost(tester, themeMode: ThemeMode.light);
      final colorScheme = Theme.of(context).colorScheme;

      expect(colorScheme.primary, AppColors.primary);
      expect(colorScheme.primaryContainer, AppColors.primary50);
      expect(colorScheme.onPrimaryContainer, AppColors.primary700);
      expect(colorScheme.surface, AppColors.surface);
      expect(colorScheme.onSurface, AppColors.textPrimary);
      expect(colorScheme.error, AppColors.error500);
      expect(colorScheme.outline, AppColors.border);
    });

    testWidgets('should map dark color scheme from dark tokens', (
      tester,
    ) async {
      final context = await _pumpThemeHost(tester, themeMode: ThemeMode.dark);
      final colorScheme = Theme.of(context).colorScheme;

      expect(colorScheme.primary, AppDarkColors.primary);
      expect(colorScheme.primaryContainer, AppDarkColors.primary50);
      expect(colorScheme.onPrimaryContainer, AppDarkColors.primary700);
      expect(colorScheme.surface, AppDarkColors.surface);
      expect(colorScheme.onSurface, AppDarkColors.textPrimary);
      expect(colorScheme.error, AppDarkColors.error500);
      expect(colorScheme.outline, AppDarkColors.border);
    });

    testWidgets(
      'should keep elevated button minimum height without forcing full width',
      (tester) async {
        final context = await _pumpThemeHost(
          tester,
          themeMode: ThemeMode.light,
        );
        final style = Theme.of(context).elevatedButtonTheme.style;
        final minimumSize = style?.minimumSize?.resolve(const <WidgetState>{});

        expect(minimumSize, isNotNull);
        expect(minimumSize!.width, 0);
        expect(minimumSize.height, 48.h);
      },
    );

    testWidgets('should configure dark theme sub themes consistently', (
      tester,
    ) async {
      final context = await _pumpThemeHost(tester, themeMode: ThemeMode.dark);
      final theme = Theme.of(context);

      expect(theme.scaffoldBackgroundColor, AppDarkColors.backgroundSecondary);
      expect(theme.cardTheme.color, AppDarkColors.surface);
      expect(theme.inputDecorationTheme.fillColor, AppDarkColors.neutral100);
      expect(theme.dividerTheme.color, AppDarkColors.divider);
      expect(
        theme.bottomNavigationBarTheme.backgroundColor,
        AppDarkColors.backgroundPrimary,
      );
    });
  });

  group('AppAdaptiveColors', () {
    testWidgets('should use light tokens in light mode', (tester) async {
      final context = await _pumpThemeHost(tester, themeMode: ThemeMode.light);

      expect(AppAdaptiveColors.surface(context), AppColors.surface);
      expect(AppAdaptiveColors.neutral150(context), AppColors.neutral150);
      expect(AppAdaptiveColors.neutral650(context), AppColors.neutral650);
      expect(AppAdaptiveColors.primary(context), AppColors.primary);
    });

    testWidgets('should use dark tokens in dark mode', (tester) async {
      final context = await _pumpThemeHost(tester, themeMode: ThemeMode.dark);

      expect(AppAdaptiveColors.surface(context), AppDarkColors.surface);
      expect(AppAdaptiveColors.neutral150(context), AppDarkColors.neutral150);
      expect(AppAdaptiveColors.neutral650(context), AppDarkColors.neutral650);
      expect(AppAdaptiveColors.primary(context), AppDarkColors.primary);
    });
  });

  group('AppTextStyles', () {
    test('should fallback to system font when family is not configured', () {
      expect(AppTextStyles.fontFamilyMedium, isNull);
      expect(AppTextStyles.fontFamilyRegular, isNull);
    });
  });
}
