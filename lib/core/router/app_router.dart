import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/guards/auth_guard.dart';
import 'package:flutter_clean_arch_template/core/router/guards/debouncer_guard.dart';
import 'package:flutter_clean_arch_template/features/_example/presentation/pages/example_detail_page.dart';
import 'package:flutter_clean_arch_template/features/_example/presentation/pages/example_list_page.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/presentation/pages/todo_list_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/master_detail_detail_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/master_detail_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_article_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_chat_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_dashboard_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_demo_hub_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_form_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_gallery_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_login_page.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/responsive_settings_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/async_when_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/dependencies_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/filter_list_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/form_submit_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/optimistic_update_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/pagination_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/pessimistic_update_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/retry_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/riverpod_demo_hub_page.dart';
import 'package:flutter_clean_arch_template/features/_riverpod_demo/presentation/pages/toast_error_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/button_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/data_display_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/dialog_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/form_input_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/navigation_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sheet_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_app_bar_hub_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_basic_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_fade_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_float_snap_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_m3_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_multi_sliver_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_stretch_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/sliver_tabbar_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/state_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/utility_demo_page.dart';
import 'package:flutter_clean_arch_template/features/_widget_demo/presentation/pages/widget_demo_hub_page.dart';
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

    // Responsive demo pages
    AutoRoute(
      page: ResponsiveDemoHubRoute.page,
      path: '/responsive-demo',
    ),
    AutoRoute(
      page: ResponsiveDashboardRoute.page,
      path: '/responsive-demo/dashboard',
    ),
    AutoRoute(
      page: MasterDetailRoute.page,
      path: '/responsive-demo/master-detail',
    ),
    AutoRoute(
      page: MasterDetailDetailRoute.page,
      path: '/responsive-demo/master-detail/detail',
    ),
    AutoRoute(
      page: ResponsiveFormRoute.page,
      path: '/responsive-demo/form',
    ),
    AutoRoute(
      page: ResponsiveGalleryRoute.page,
      path: '/responsive-demo/gallery',
    ),
    AutoRoute(
      page: ResponsiveSettingsRoute.page,
      path: '/responsive-demo/settings',
    ),
    AutoRoute(
      page: ResponsiveArticleRoute.page,
      path: '/responsive-demo/article',
    ),
    AutoRoute(
      page: ResponsiveLoginRoute.page,
      path: '/responsive-demo/login',
    ),
    AutoRoute(
      page: ResponsiveChatRoute.page,
      path: '/responsive-demo/chat',
    ),

    // Widget demo pages
    AutoRoute(
      page: WidgetDemoHubRoute.page,
      path: '/widget-demo',
    ),
    AutoRoute(
      page: ButtonDemoRoute.page,
      path: '/widget-demo/button',
    ),
    AutoRoute(
      page: DialogDemoRoute.page,
      path: '/widget-demo/dialog',
    ),
    AutoRoute(
      page: SheetDemoRoute.page,
      path: '/widget-demo/sheet',
    ),
    AutoRoute(
      page: DataDisplayDemoRoute.page,
      path: '/widget-demo/data-display',
    ),
    AutoRoute(
      page: FormInputDemoRoute.page,
      path: '/widget-demo/form-input',
    ),
    AutoRoute(
      page: StateDemoRoute.page,
      path: '/widget-demo/state',
    ),
    AutoRoute(
      page: NavigationDemoRoute.page,
      path: '/widget-demo/navigation',
    ),
    AutoRoute(
      page: UtilityDemoRoute.page,
      path: '/widget-demo/utility',
    ),
    AutoRoute(
      page: SliverAppBarHubRoute.page,
      path: '/widget-demo/sliver-app-bar',
    ),
    AutoRoute(
      page: SliverBasicDemoRoute.page,
      path: '/widget-demo/sliver-basic',
    ),
    AutoRoute(
      page: SliverFloatSnapDemoRoute.page,
      path: '/widget-demo/sliver-float-snap',
    ),
    AutoRoute(
      page: SliverStretchDemoRoute.page,
      path: '/widget-demo/sliver-stretch',
    ),
    AutoRoute(
      page: SliverTabbarDemoRoute.page,
      path: '/widget-demo/sliver-tabbar',
    ),
    AutoRoute(
      page: SliverFadeDemoRoute.page,
      path: '/widget-demo/sliver-fade',
    ),
    AutoRoute(
      page: SliverM3DemoRoute.page,
      path: '/widget-demo/sliver-m3',
    ),
    AutoRoute(
      page: SliverMultiSliverDemoRoute.page,
      path: '/widget-demo/sliver-multi',
    ),

    // Riverpod demo pages
    AutoRoute(
      page: RiverpodDemoHubRoute.page,
      path: '/riverpod-demo',
    ),
    AutoRoute(
      page: AsyncWhenDemoRoute.page,
      path: '/riverpod-demo/async-when',
    ),
    AutoRoute(
      page: ToastErrorDemoRoute.page,
      path: '/riverpod-demo/toast-error',
    ),
    AutoRoute(
      page: PaginationDemoRoute.page,
      path: '/riverpod-demo/pagination',
    ),
    AutoRoute(
      page: OptimisticUpdateDemoRoute.page,
      path: '/riverpod-demo/optimistic-update',
    ),
    AutoRoute(
      page: FilterListDemoRoute.page,
      path: '/riverpod-demo/filter-list',
    ),
    AutoRoute(
      page: FormSubmitDemoRoute.page,
      path: '/riverpod-demo/form-submit',
    ),
    AutoRoute(
      page: RetryDemoRoute.page,
      path: '/riverpod-demo/retry',
    ),
    AutoRoute(
      page: PessimisticUpdateDemoRoute.page,
      path: '/riverpod-demo/pessimistic-update',
    ),
    AutoRoute(
      page: DependenciesDemoRoute.page,
      path: '/riverpod-demo/dependencies',
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
