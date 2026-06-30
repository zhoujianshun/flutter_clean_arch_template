import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/shared/utils/responsive_utils.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用壳层页面（自适应导航）
///
/// 根据屏幕宽度自动切换导航形式：
/// - 手机（< 600dp）：底部 [NavigationBar]
/// - 平板竖屏（600-1023dp）：左侧 [NavigationRail]（仅图标 + 选中标签）
/// - 平板横屏/桌面（>= 1024dp）：左侧 [NavigationRail]（图标 + 所有标签）
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
  static const _destinations = <({IconData icon, IconData selectedIcon, String label})>[
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: AutoTabsRouter(
        routes: const [
          ExampleListRoute(),
          ProfileRoute(),
        ],
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          return LayoutBuilder(
            builder: (context, constraints) {
              if (ResponsiveUtils.isCompact(constraints)) {
                return _buildCompactShell(tabsRouter, child);
              }
              return _buildMediumShell(tabsRouter, child, constraints);
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, TabsRouter tabsRouter) {
    if (Platform.isIOS) {
      return CupertinoTabBar(
        currentIndex: tabsRouter.activeIndex,
        onTap: tabsRouter.setActiveIndex,
        activeColor: Theme.of(context).colorScheme.primary,
        // height: _iosTabBarHeight,
        iconSize: _iosTabIconSize,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: _iosTabIconTopPadding),
              child: Icon(CupertinoIcons.house),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: _iosTabIconTopPadding),
              child: Icon(CupertinoIcons.house_fill),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: _iosTabIconTopPadding),
              child: Icon(CupertinoIcons.person),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: _iosTabIconTopPadding),
              child: Icon(CupertinoIcons.person_fill),
            ),
            label: 'Profile',
          ),
        ],
      );
    }

    return NavigationBar(
      selectedIndex: tabsRouter.activeIndex,
      onDestinationSelected: tabsRouter.setActiveIndex,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
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
            labelType: ResponsiveUtils.isExpanded(constraints)
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.selected,
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
    if (_lastPressedAt != null && now.difference(_lastPressedAt!).inMilliseconds < _exitTimeWindow) {
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
