import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/core/constants/app_constants.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/core/responsive/layout_semantics.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/widgets/navigation/my_bottom_navigation_bar.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用壳层页面（自适应导航）
///
/// 根据屏幕宽度自动切换导航形式：
/// - 手机（< 600dp）：底部 [MyBottomNavigationBar]
/// - 平板竖屏（600-839dp）：左侧 [NavigationRail]（仅图标 + 选中标签）
/// - 平板横屏/桌面（>= 840dp）：左侧 [NavigationRail]（图标 + 所有标签）
///
/// ### iPhone Duo 适配说明
///
/// iPhone Duo 内屏（~951×669dp）会触发 medium/expanded 布局，使用左侧
/// [NavigationRail]。在横屏模式下，iOS 系统将状态栏、导航按钮、Tab 等控件
/// 合并到**右侧 84dp 的垂直控件条带**中（Vertical Controls）。
///
/// Flutter 自绘的 Widget（`AppBar`、`NavigationBar`、`CupertinoTabBar`）
/// 不会被系统整合到垂直条带中——这是 Flutter 框架级限制。系统只移动由
/// `UINavigationController` / `UITabBarController` 管理的原生 bar。
///
/// **当前行为**：
/// - 横屏：[NavigationRail] 在左侧，系统垂直条带在右侧（[SafeArea] 84dp），
///   各页面的 [AppBar] 保持水平。状态栏项目（时间/WiFi）在右侧条带内垂直排列。
/// - 竖屏：回到标准水平布局（[NavigationRail] + 顶部 [AppBar]）。
///
/// **与原生 App 的差异**：Safari 等使用 UIKit 导航容器的原生 App，
/// 其导航栏会被系统自动整合到垂直条带中，视觉更统一。
/// 如需一致体验，可使用 `nitro_fold_duo` 或 `iphone_duo_layout` 等插件
/// 桥接原生 bar，但这些插件需要 iOS 27.1 SDK 且目前为预发布版本。
@RoutePage()
class AppShellPage extends ConsumerStatefulWidget {
  const AppShellPage({super.key});

  @override
  ConsumerState<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends ConsumerState<AppShellPage> {
  DateTime? _lastPressedAt;
  static const int _exitTimeWindow = 2000;

  /// NavigationRail 的最小宽度（图标模式 ~72dp + 余量）。
  static const double _railWidth = 80;

  /// 分隔线宽度。
  static const double _dividerWidth = 1;

  /// 使用 NavigationRail 时内容区的最小可用宽度。
  /// 低于此值时回退到底部导航，避免内容拥挤。
  static const double _minContentWidth = 400;

  /// 导航目的地配置（共享给 MyBottomNavigationBar 和 NavigationRail）
  static List<({IconData icon, IconData selectedIcon, String label})>
  get _destinations => AppConstants.includeDemos
      ? const [
          (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
          (
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ]
      : const [
          (
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ];

  static List<PageRouteInfo> get _tabRoutes => AppConstants.includeDemos
      ? const [ExampleListRoute(), ProfileRoute()]
      : const [ProfileRoute()];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: AutoTabsRouter(
        routes: _tabRoutes,
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          return AdaptiveLayoutBuilder(
            compact: (_) => _buildCompactShell(tabsRouter, child),
            medium: (constraints) {
              // 复合条件：断点达到 medium 但内容区不足时回退到 compact 布局，
              // 避免 SafeArea/系统侧栏扣除后 Rail + 内容区过于拥挤。
              final availableContent =
                  constraints.maxWidth - _railWidth - _dividerWidth;
              if (availableContent < _minContentWidth) {
                return _buildCompactShell(tabsRouter, child);
              }
              return _buildMediumShell(tabsRouter, child, constraints);
            },
          );
        },
      ),
    );
  }

  /// 手机布局：底部导航栏
  Widget _buildCompactShell(TabsRouter tabsRouter, Widget child) {
    return Scaffold(
      body: child,
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: tabsRouter.activeIndex,
        onTap: tabsRouter.setActiveIndex,
        destinations: _destinations,
      ),
    );
  }

  /// 平板/桌面布局：左侧导航栏
  Widget _buildMediumShell(
    TabsRouter tabsRouter,
    Widget child,
    BoxConstraints constraints,
  ) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: tabsRouter.activeIndex,
            onDestinationSelected: tabsRouter.setActiveIndex,
            labelType: LayoutSemantics.railLabelType(constraints),
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _handleBackPress() {
    final now = DateTime.now();
    if (_lastPressedAt != null &&
        now.difference(_lastPressedAt!).inMilliseconds < _exitTimeWindow) {
      AppLogger.info('AppShell: Double-tap exit');
      if (defaultTargetPlatform == TargetPlatform.android) {
        unawaited(SystemNavigator.pop());
      }
      return;
    }
    _lastPressedAt = now;
    MyEasyPopMessage.showToastUnawaited('Press again to exit');
  }
}
