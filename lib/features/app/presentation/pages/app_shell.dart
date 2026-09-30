import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/core/constants/app_constants.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/layout_semantics.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用壳层页面（自适应导航）
///
/// 根据屏幕宽度自动切换导航形式：
/// - 手机（< 600dp）：底部 [NavigationBar]
/// - 平板竖屏（600-839dp）：左侧 [NavigationRail]（仅图标 + 选中标签）
/// - 平板横屏/桌面（>= 840dp）：左侧 [NavigationRail]（图标 + 所有标签）
@RoutePage()
class AppShellPage extends ConsumerStatefulWidget {
  const AppShellPage({super.key});

  @override
  ConsumerState<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends ConsumerState<AppShellPage> {
  DateTime? _lastPressedAt;
  static const int _exitTimeWindow = 2000;
  // static const double _iosTabBarHeight = 56;
  static const double _iosTabIconTopPadding = 6;
  static const double _iosTabIconSize = 24;

  /// 导航目的地配置（共享给 NavigationBar 和 NavigationRail）
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
            medium: (constraints) =>
                _buildMediumShell(tabsRouter, child, constraints),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    TabsRouter tabsRouter,
  ) {
    if (Platform.isIOS) {
      return CupertinoTabBar(
        currentIndex: tabsRouter.activeIndex,
        onTap: tabsRouter.setActiveIndex,
        activeColor: Theme.of(context).colorScheme.primary,
        // height: _iosTabBarHeight,
        iconSize: _iosTabIconSize,
        items: _destinations
            .map(
              (destination) => BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(
                    top: _iosTabIconTopPadding,
                  ),
                  child: Icon(destination.icon),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(
                    top: _iosTabIconTopPadding,
                  ),
                  child: Icon(destination.selectedIcon),
                ),
                label: destination.label,
              ),
            )
            .toList(growable: false),
      );
    }

    return NavigationBar(
      selectedIndex: tabsRouter.activeIndex,
      onDestinationSelected: tabsRouter.setActiveIndex,
      destinations: _destinations
          .map(
            (destination) => NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
          )
          .toList(growable: false),
    );
  }

  /// 手机布局：底部导航栏
  Widget _buildCompactShell(TabsRouter tabsRouter, Widget child) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context, tabsRouter),
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
      if (Platform.isAndroid) {
        unawaited(SystemNavigator.pop());
      }
      return;
    }
    _lastPressedAt = now;
    MyEasyPopMessage.showToastUnawaited('Press again to exit');
  }
}
