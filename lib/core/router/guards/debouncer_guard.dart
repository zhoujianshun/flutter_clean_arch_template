import 'package:auto_route/auto_route.dart';
import 'package:flutter_clean_arch_template/core/router/utils/navigation_debouncer.dart';
import 'package:injectable/injectable.dart';

/// 导航防抖动守卫
///
/// 在路由层面防止快速连续导航到同一个路由
/// 使用场景：防止用户快速点击导致重复push相同页面
@singleton
class DebouncerGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final routeName = resolver.route.name;

    // 检查是否应该阻止导航
    if (!NavigationDebouncer.instance.canNavigate(routeName)) {
      // 阻止导航，不调用 resolver.next()
      return;
    }

    // 允许导航
    resolver.next();
  }
}
