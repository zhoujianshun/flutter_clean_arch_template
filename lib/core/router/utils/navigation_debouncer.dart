import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// 导航防抖动器
///
/// 防止快速连续点击导致重复导航
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

/// 扩展 StackRouter 添加防抖动导航方法
extension DebouncedRouterExtension on StackRouter {
  /// 带防抖动的 push
  Future<T?>? pushDebounced<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    final routeName = route.routeName;

    if (!NavigationDebouncer.instance.canNavigate(routeName)) {
      return null;
    }

    return push<T>(route, onFailure: onFailure);
  }

  /// 带防抖动的 replace
  Future<T?>? replaceDebounced<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    final routeName = route.routeName;

    if (!NavigationDebouncer.instance.canNavigate(routeName)) {
      return null;
    }

    return replace<T>(route, onFailure: onFailure);
  }

  /// 带防抖动的 navigate
  Future<void>? navigateDebounced(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    final routeName = route.routeName;

    if (!NavigationDebouncer.instance.canNavigate(routeName)) {
      return null;
    }

    return navigate(route, onFailure: onFailure);
  }
}

/// BuildContext 扩展，提供便捷的防抖动导航方法
extension DebouncedNavigationExtension on BuildContext {
  /// 带防抖动的 push
  Future<T?>? pushDebounced<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    return router.pushDebounced<T>(route, onFailure: onFailure);
  }

  /// 带防抖动的 replace
  Future<T?>? replaceDebounced<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    return router.replaceDebounced<T>(route, onFailure: onFailure);
  }

  /// 带防抖动的 navigate
  Future<void>? navigateDebounced(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    return router.navigateDebounced(route, onFailure: onFailure);
  }
}
