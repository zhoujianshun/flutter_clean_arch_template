import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// 导航防抖动器
///
/// 防止快速连续点击导致重复导航。
/// 由 [DebouncerGuard]（core/router/guards/）在路由层统一调用，
/// 记录与检查都在本类内完成——调用方只管 push，不需要（也不能）自行检查，
/// 否则双重检查会互相冲突导致导航被误吞。
class NavigationDebouncer {
  NavigationDebouncer._();

  static final NavigationDebouncer _instance = NavigationDebouncer._();
  static NavigationDebouncer get instance => _instance;

  // 记录最后一次导航的时间和路由
  DateTime? _lastNavigationTime;
  String? _lastRouteName;

  // 防抖动间隔（毫秒）
  static const int _debounceMilliseconds = 500;

  /// 检查是否可以导航
  ///
  /// 如果距离上次导航到相同路由的时间太短，返回 false
  bool canNavigate(String routeName) {
    final now = DateTime.now();

    // 如果是第一次导航，允许
    if (_lastNavigationTime == null) {
      _recordNavigation(routeName, now);
      return true;
    }

    // 如果导航到不同的路由，允许
    if (_lastRouteName != routeName) {
      _recordNavigation(routeName, now);
      return true;
    }

    // 如果导航到相同路由，检查时间间隔
    final timeDiff = now.difference(_lastNavigationTime!).inMilliseconds;

    if (timeDiff < _debounceMilliseconds) {
      AppLogger.warning(
        '导航防抖动: 忽略到 $routeName 的重复导航 (间隔: ${timeDiff}ms)',
      );
      return false;
    }

    _recordNavigation(routeName, now);
    return true;
  }

  /// 记录导航
  void _recordNavigation(String routeName, DateTime time) {
    _lastRouteName = routeName;
    _lastNavigationTime = time;
  }

  /// 重置防抖动状态
  void reset() {
    _lastNavigationTime = null;
    _lastRouteName = null;
  }
}
