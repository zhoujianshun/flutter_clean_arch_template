import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/guards/auth_guard.dart';
import 'package:flutter_clean_arch_template/core/router/guards/debouncer_guard.dart';
import 'package:flutter_clean_arch_template/features/_example/presentation/pages/example_detail_page.dart';
import 'package:flutter_clean_arch_template/features/_example/presentation/pages/example_list_page.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/presentation/pages/todo_list_page.dart';
import 'package:flutter_clean_arch_template/features/app/presentation/pages/app_shell.dart';
import 'package:flutter_clean_arch_template/features/app/presentation/pages/config_management_page/config_management_page.dart';
import 'package:flutter_clean_arch_template/features/app/presentation/pages/onboarding_page/onboarding_page.dart';
import 'package:flutter_clean_arch_template/features/app/presentation/pages/settings_page/logger_viewer_page.dart';
import 'package:flutter_clean_arch_template/features/app/presentation/pages/settings_page/theme_settings_page.dart';
import 'package:flutter_clean_arch_template/features/app/presentation/pages/splash_page/splash_page.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/pages/login_page/login_page.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/pages/profile_page/profile_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter({
    required this.authGuard,
    required this.debouncerGuard,
  });

  final AuthGuard authGuard;
  final DebouncerGuard debouncerGuard;

  @override
  RouteType get defaultRouteType => const RouteType.cupertino();

  @override
  List<AutoRoute> get routes => [
    CustomRoute<SplashRoute>(
      page: SplashRoute.page,
      path: '/splash',
      initial: true,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      duration: const Duration(milliseconds: 400),
    ),
    AutoRoute(
      page: OnboardingRoute.page,
      path: '/onboarding',
    ),
    CustomRoute<LoginRoute>(
      page: LoginRoute.page,
      path: '/auth/login',
      transitionsBuilder: TransitionsBuilders.fadeIn,
      duration: const Duration(milliseconds: 400),
    ),

    // Example feature pages
    AutoRoute(
      page: ExampleDetailRoute.page,
      path: '/example-detail/:itemId',
    ),

    // Simple example (pragmatic pattern)
    AutoRoute(
      page: TodoListRoute.page,
      path: '/todos',
    ),

    // Dev tools
    AutoRoute(
      page: ConfigManagementRoute.page,
      path: '/config-management',
    ),
    AutoRoute(
      page: LoggerViewerRoute.page,
      path: '/logger-viewer',
    ),
    AutoRoute(
      page: ThemeSettingsRoute.page,
      path: '/theme-settings',
    ),

    // Shell (bottom navigation)
    AutoRoute(
      page: AppShellRoute.page,
      path: '/app',
      children: [
        AutoRoute(
          page: ExampleListRoute.page,
          path: 'home',
          initial: true,
        ),
        AutoRoute(
          page: ProfileRoute.page,
          path: 'profile',
        ),
      ],
    ),

    RedirectRoute(path: '*', redirectTo: '/splash'),
  ];

  @override
  List<AutoRouteGuard> get guards => [debouncerGuard, authGuard];
}
