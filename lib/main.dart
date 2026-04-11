import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/initializers/app_initializer.dart';
import 'package:flutter_clean_arch_template/core/l10n/language_provider.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/router_provider.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/core/theme/theme_mode_provider.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/widgets/auth_navigation_listener.dart';
import 'package:flutter_clean_arch_template/generated/l10n/app_localizations.dart';
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
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
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
