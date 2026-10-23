import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 平台自适应底部导航栏。
///
/// 内部根据 [Theme.of(context).platform] 分叉：
/// - iOS / macOS → [CupertinoTabBar]
/// - 其他平台 → Material [NavigationBar]
///
/// 页面层只需使用此组件，不必关心平台差异。
/// 未来接入 Liquid Glass（如 `native_liquid_glass` 的 NativeTabBar）时，
/// 只需修改此文件的 iOS 分支，所有页面自动获得新材质。
///
/// ```dart
/// MyBottomNavigationBar(
///   currentIndex: tabsRouter.activeIndex,
///   onTap: tabsRouter.setActiveIndex,
///   destinations: [
///     (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
///     (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
///   ],
/// )
/// ```
class MyBottomNavigationBar extends StatelessWidget {
  const MyBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    super.key,
  });

  /// 当前选中的导航项索引。
  final int currentIndex;

  /// 点击导航项时的回调。
  final ValueChanged<int> onTap;

  /// 导航目的地列表。
  final List<({IconData icon, IconData selectedIcon, String label})>
      destinations;

  // iOS 专用常量
  static const double _iosTabIconTopPadding = 6;
  static const double _iosTabIconSize = 24;

  @override
  Widget build(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => _buildCupertinoTabBar(context),
      _ => _buildMaterialNavigationBar(context),
    };
  }

  Widget _buildCupertinoTabBar(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: Theme.of(context).colorScheme.primary,
      iconSize: _iosTabIconSize,
      items: destinations
          .map(
            (destination) => BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: _iosTabIconTopPadding),
                child: Icon(destination.icon),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(top: _iosTabIconTopPadding),
                child: Icon(destination.selectedIcon),
              ),
              label: destination.label,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildMaterialNavigationBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: destinations
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
}
