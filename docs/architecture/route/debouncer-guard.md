# DebouncerGuard - 路由防抖动守卫

## 概述

`DebouncerGuard` 是一个 `auto_route` 路由守卫，用于在路由层面自动防止用户快速连续导航到同一个路由。相比于在每个点击处手动实现防抖动逻辑，使用路由守卫的方式更加优雅、系统化和易于维护。

## 特性

- **自动防抖动**：无需在每个导航调用处手动处理防抖动
- **可配置间隔**：默认 500ms，可根据需要调整
- **路由级别控制**：可以选择性地应用到需要防抖动的路由上
- **自动注入**：通过 `injectable` 自动注册到依赖注入容器

## 实现原理

`DebouncerGuard` 实现了 `AutoRouteGuard` 接口，在每次导航前检查：

1. 是否导航到相同的路由
2. 距离上次导航的时间间隔是否小于阈值（默认 500ms）

如果满足上述两个条件，则阻止本次导航；否则允许导航并记录本次导航信息。

## 核心代码

```dart
import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// 导航防抖动守卫
///
/// 在路由层面防止快速连续导航到同一个路由
/// 使用场景：防止用户快速点击导致重复push相同页面
@singleton
class DebouncerGuard extends AutoRouteGuard {
 // 记录最后一次导航的时间和路由
 DateTime? _lastNavigationTime;
 String? _lastRouteName;

 // 防抖动间隔（毫秒）
 static const int _debounceMilliseconds = 500;

 @override
 void onNavigation(NavigationResolver resolver, StackRouter router) {
 final routeName = resolver.route.name;
 final now = DateTime.now();

 // 检查是否应该阻止导航
 if (_shouldBlockNavigation(routeName, now)) {
 AppLogger.warning(
 '路由守卫: 阻止重复导航到 $routeName (间隔: ${_getTimeDiff(now)}ms)',
 );
 // 阻止导航，不调用 resolver.next()
 return;
 }

 // 记录本次导航
 _recordNavigation(routeName, now);

 // 允许导航
 resolver.next();
 }

 /// 检查是否应该阻止导航
 bool _shouldBlockNavigation(String routeName, DateTime now) {
 // 第一次导航，允许
 if (_lastNavigationTime == null) {
 return false;
 }

 // 导航到不同路由，允许
 if (_lastRouteName != routeName) {
 return false;
 }

 // 导航到相同路由，检查时间间隔
 final timeDiff = now.difference(_lastNavigationTime!).inMilliseconds;
 return timeDiff < _debounceMilliseconds;
 }

 /// 获取时间差（毫秒）
 int _getTimeDiff(DateTime now) {
 if (_lastNavigationTime == null) return 0;
 return now.difference(_lastNavigationTime!).inMilliseconds;
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
```

## 使用方法

### 1. 在 AppRouter 中引入 DebouncerGuard

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
 AppRouter({
 required this.authGuard,
 required this.debouncerGuard, // 注入防抖动守卫
 });

 final AuthGuard authGuard;
 final DebouncerGuard debouncerGuard;

 @override
 List<AutoRoute> get routes => [
 // 需要防抖动的路由（订单详情页）
 AutoRoute(
 page: ExampleDetailRoute.page,
 path: '/order-detail/:orderId',
 guards: [authGuard, debouncerGuard], // 应用防抖动守卫
 ),

 // 需要防抖动的路由（服务统计详情页）
 AutoRoute(
 page: ExampleStatsDetailRoute.page,
 path: '/service-order-stats-detail/:statsType',
 guards: [authGuard, debouncerGuard], // 应用防抖动守卫
 ),

 // 需要防抖动的路由（公告详情页）
 AutoRoute(
 page: AnnouncementDetailRoute.page,
 path: '/announcement-detail/:messageId',
 guards: [authGuard, debouncerGuard], // 应用防抖动守卫
 ),

 // 不需要防抖动的路由（启动页）
 CustomRoute(
 page: SplashRoute.page,
 path: '/splash',
 initial: true,
 transitionsBuilder: TransitionsBuilders.fadeIn,
 duration: const Duration(milliseconds: 400),
 // 不添加 debouncerGuard
 ),
 ];
}
```

### 2. 在 RouterProvider 中注入 DebouncerGuard

```dart
@Riverpod(keepAlive: true)
Raw<AppRouter> appRouter(Ref ref) {
 return AppRouter(
 authGuard: getIt<AuthGuard>(),
 debouncerGuard: getIt<DebouncerGuard>(), // 从依赖注入容器获取
 );
}
```

### 3. 在页面中正常使用导航

无需任何特殊处理，直接使用 `context.router.push` 即可，路由守卫会自动处理防抖动：

```dart
// 导航到订单详情页（自动防抖动）
context.router.push(
 ExampleDetailRoute(orderId: orderId),
);

// 导航到服务统计详情页（自动防抖动）
context.router.push(
 ExampleStatsDetailRoute(statsType: statsType),
);
```

## 适用场景

建议为以下类型的路由应用 `DebouncerGuard`：

- **详情页面**：如订单详情、商品详情、用户详情等
- **列表跳转**：从列表页跳转到详情页的场景
- **表单页面**：可能涉及数据提交的页面
- **设置页面**：如主题设置、日志查看器等工具页面

## 不建议应用的场景

以下场景不建议应用防抖动守卫：

- **底部导航切换**：用户切换底部Tab应该立即响应
- **登录/注册页面**：这些页面通常不会快速重复导航
- **启动页/引导页**：这些页面由系统控制，不会重复导航

## 调试日志

当路由守卫阻止重复导航时，会输出警告日志：

```
路由守卫: 阻止重复导航到 ExampleDetailRoute (间隔: 120ms)
```

这有助于在开发阶段发现和调试防抖动问题。

## 与手动防抖动的对比

### 手动防抖动（之前的方式）

```dart
// 需要在每个导航调用处使用 pushDebounced
context.pushDebounced(
 ExampleDetailRoute(orderId: orderId),
);
```

**缺点：**
- 需要在每个地方都记得使用 `pushDebounced`
- 容易遗漏
- 代码侵入性强

### 路由守卫（推荐方式）

```dart
// 直接使用 push，路由守卫自动处理防抖动
context.router.push(
 ExampleDetailRoute(orderId: orderId),
);
```

**优点：**
- 在路由配置层面统一管理
- 不需要修改已有的导航调用代码
- 代码更简洁，易于维护
- 不会遗漏

## 自定义配置

如果需要调整防抖动间隔，可以修改 `DebouncerGuard` 中的常量：

```dart
// 默认 500ms
static const int _debounceMilliseconds = 500;

// 修改为 300ms（更激进的防抖动）
static const int _debounceMilliseconds = 300;

// 修改为 1000ms（更保守的防抖动）
static const int _debounceMilliseconds = 1000;
```

## 总结

`DebouncerGuard` 提供了一种优雅、系统化的方式来处理导航防抖动问题。通过在路由配置层面应用守卫，可以避免在每个导航调用处手动处理防抖动逻辑，使代码更加简洁和易于维护。

建议在所有可能因用户快速点击而重复导航的路由上应用此守卫。

