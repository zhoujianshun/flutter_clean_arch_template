import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/initializers/app_initializer.dart';
import 'package:flutter_clean_arch_template/core/l10n/language_provider.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/router_provider.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/core/theme/theme_mode_provider.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/widgets/auth_navigation_listener.dart';
import 'package:flutter_clean_arch_template/generated/l10n/app_localizations.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize(widgetsBinding);

  runApp(
    ProviderScope(
      observers: [
        if (AppLogger.riverpodObserver != null) AppLogger.riverpodObserver!,
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return ScreenUtilInit(
      designSize: const Size(
        ResponsiveUtils.phoneDesignWidth,
        ResponsiveUtils.phoneDesignHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      fontSizeResolver: (fontSize, instance) {
        // 平板/桌面端（>= 600dp）：不缩放字体，直接使用设计稿 dp 值
        if (instance.screenWidth >= ResponsiveUtils.compactBreakpoint) {
          return fontSize.toDouble();
        }
        // 手机端：宽高混合缩放，避免极端屏幕比例下字体失真
        final scaleW = instance.screenWidth / ResponsiveUtils.phoneDesignWidth;
        final scaleH = instance.screenHeight / ResponsiveUtils.phoneDesignHeight;
        final scale = min(scaleW, scaleH) * 0.85 + max(scaleW, scaleH) * 0.15;
        return fontSize * scale;
      },
      builder: (context, child) {
        return AuthNavigationListener(
          child: KeyboardDismissOnTap(
            dismissOnCapturedTaps: true,
            child: MaterialApp.router(
              title: 'Flutter Clean Arch',
              routerConfig: appRouter.config(
                navigatorObservers: () => [
                  if (AppLogger.routeObserver != null) AppLogger.routeObserver!,
                ],
              ),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              builder: EasyLoading.init(),
              debugShowCheckedModeBanner: false,
            ),
          ),
        );
      },
    );
  }
}
