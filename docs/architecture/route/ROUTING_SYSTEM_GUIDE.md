# 路由系统完整指南

> 本项目使用 `auto_route ^10.2.0` 实现类型安全的路由导航系统

## 目录

- [概述](#概述)
- [快速开始](#快速开始)
- [核心组件](#核心组件)
- [基础用法](#基础用法)
- [高级特性](#高级特性)
- [路由守卫](#路由守卫)
- [最佳实践](#最佳实践)
- [常见问题](#常见问题)

## 概述

### 核心特性

- ✅ **编译期类型检查**: 所有路由在编译期验证，避免运行时错误
- ✅ **代码生成**: 自动生成类型安全的路由代码
- ✅ **路由守卫**: 支持 `AuthGuard` 和 `DebouncerGuard`
- ✅ **防抖导航**: 自动防止快速重复导航
- ✅ **Shell路由**: 支持底部导航栏的 `AutoTabsRouter`
- ✅ **自定义转场**: 支持多种页面转场动画
- ✅ **深度链接**: 支持路径参数和查询参数

### 技术栈

```yaml
auto_route: ^10.2.0 # 路由管理
auto_route_generator: ^10.2.5 # 代码生成
injectable: ^2.5.1 # 依赖注入
riverpod: ^3.0.0 # 状态管理
```

## 快速开始

### 1. 创建页面并添加注解

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomePage extends StatelessWidget {
 const HomePage({super.key});

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(title: const Text('首页')),
 body: const Center(child: Text('欢迎')),
 );
 }
}
```

### 2. 在 AppRouter 中注册路由

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
 @override
 List<AutoRoute> get routes => [
 AutoRoute(
 page: HomeRoute.page,
 path: '/home',
 initial: true,
 ),
 ];
}
```

### 3. 运行代码生成

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. 导航到页面

```dart
// 方式一：使用生成的路由类
context.router.push(const HomeRoute());

// 方式二：替换所有路由
context.router.replaceAll([const HomeRoute()]);

// 方式三：返回上一页
context.router.pop();
```

## 核心组件

### 1. AppRouter - 路由配置

**文件位置**: `lib/core/router/app_router.dart`

**核心功能**:

- 定义所有路由
- 配置路由守卫
- 自定义转场动画

**完整示例**:

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/router/guards/auth_guard.dart';
import 'package:flutter_clean_arch_template/core/router/guards/debouncer_guard.dart';
// ... 导入所有页面

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
 List<AutoRoute> get routes => [
 // 启动页 - Fade 动画
 CustomRoute(
 page: SplashRoute.page,
 path: '/splash',
 initial: true,
 transitionsBuilder: TransitionsBuilders.fadeIn,
 duration: const Duration(milliseconds: 400),
 ),

 // 登录页
 AutoRoute(
 page: LoginRoute.page,
 path: '/auth/login',
 ),

 // 订单详情页（需要认证 + 防抖动）
 AutoRoute(
 page: ExampleDetailRoute.page,
 path: '/order-detail/:orderId',
 ),

 // Shell 路由（底部导航）
 AutoRoute(
 page: AppShellRoute.page,
 path: '/app',
 children: [
 AutoRoute(
 page: HomeTabRoute.page,
 path: 'home',
 initial: true,
 ),
 AutoRoute(
 page: NotificationRoute.page,
 path: 'message-center',
 ),
 AutoRoute(
 page: ProfileRoute.page,
 path: 'profile',
 ),
 ],
 ),

 // 404 处理
 RedirectRoute(path: '*', redirectTo: '/splash'),
 ];

 @override
 List<AutoRouteGuard> get guards => [debouncerGuard, authGuard];
}
```

### 2. RouterProvider - Riverpod 集成

**文件位置**: `lib/core/router/router_provider.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/core/router/guards/auth_guard.dart';
import 'package:flutter_clean_arch_template/core/router/guards/debouncer_guard.dart';

part 'router_provider.g.dart';

/// AppRouter Provider
/// 提供 AppRouter 实例，包含认证守卫、防抖动守卫和导航观察者
@Riverpod(keepAlive: true)
Raw<AppRouter> appRouter(Ref ref) {
 return AppRouter(
 authGuard: getIt<AuthGuard>(),
 debouncerGuard: getIt<DebouncerGuard>(),
 );
}
```

### 3. 在 main.dart 中使用

```dart
class MyApp extends ConsumerWidget {
 const MyApp({required this.observer, super.key});

 final NavigatorObserver observer;

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final appRouter = ref.watch(appRouterProvider);

 return MaterialApp.router(
 title: 'Your App',
 routerConfig: appRouter.config(
 navigatorObservers: () => [
 observer,
 AppLogger.routeObserver!,
 ],
 ),
 // ... 其他配置
 );
 }
}
```

## 基础用法

### 1. 基础导航

```dart
// 推送新页面
context.router.push(const OrderDetailRoute(orderId: '123'));

// 替换当前页面
context.router.replace(const LoginRoute());

// 替换所有路由
context.router.replaceAll([const AppShellRoute()]);

// 返回上一页
context.router.pop();

// 返回上一页并传递结果
context.router.pop<String>('result_data');

// 返回到指定路由
context.router.popUntil((route) => route.settings.name == 'home');
```

### 2. 路径参数

```dart
// 定义带路径参数的页面
@RoutePage()
class OrderDetailPage extends StatelessWidget {
 const OrderDetailPage({
 @PathParam('orderId') required this.orderId, // 路径参数
 super.key,
 });

 final String orderId;
 // ...
}

// 在 AppRouter 中定义路由
AutoRoute(
 page: ExampleDetailRoute.page,
 path: '/order-detail/:orderId', // :orderId 是路径参数
),

// 导航时传递参数
context.router.push(ExampleDetailRoute(orderId: '123'));
```

### 3. 查询参数

```dart
// 定义带查询参数的页面
@RoutePage()
class OrderDetailPage extends StatelessWidget {
 const OrderDetailPage({
 @PathParam('orderId') required this.orderId,
 @QueryParam('showAlert') this.showAlert = false, // 查询参数
 super.key,
 });

 final String orderId;
 final bool showAlert;
 // ...
}

// 导航时传递查询参数
context.router.push(
 ExampleDetailRoute(
 orderId: '123',
 showAlert: true,
 ),
);
```

### 4. 检查导航状态

```dart
// 检查是否可以返回
if (context.router.canPop()) {
 context.router.pop();
}

// 获取当前路由
final currentRoute = context.router.current;
print('当前路由: ${currentRoute.name}');

// 检查是否在特定路由
if (context.router.current.name == LoginRoute.name) {
 // 当前在登录页
}
```

## 高级特性

### 1. Shell 路由（底部导航）

**AutoTabsRouter** 用于实现带底部导航栏的多标签页面。

**AppShell 实现**:

```dart
@RoutePage()
class AppShellPage extends ConsumerStatefulWidget {
 const AppShellPage({super.key});

 @override
 ConsumerState<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends ConsumerState<AppShellPage> {
 @override
 Widget build(BuildContext context) {
 return AutoTabsRouter(
 routes: [
 const HomeTabRoute(),
 const NotificationRoute(),
 const ProfileRoute(),
 ],
 builder: (context, child) {
 final tabsRouter = AutoTabsRouter.of(context);

 return Scaffold(
 body: child,
 bottomNavigationBar: BottomNavigationBar(
 currentIndex: tabsRouter.activeIndex,
 onTap: (index) {
 tabsRouter.setActiveIndex(index);
 },
 items: [
 MyBottomNavigationBarItem('首页', 'home'),
 MyBottomNavigationBarItem('通知', 'notification'),
 MyBottomNavigationBarItem('我的', 'profile'),
 ],
 ),
 );
 },
 );
 }
}
```

**在 AppRouter 中定义**:

```dart
AutoRoute(
 page: AppShellRoute.page,
 path: '/app',
 children: [
 AutoRoute(
 page: HomeTabRoute.page,
 path: 'home',
 initial: true,
 ),
 AutoRoute(
 page: NotificationRoute.page,
 path: 'message-center',
 ),
 AutoRoute(
 page: ProfileRoute.page,
 path: 'profile',
 ),
 ],
),
```

### 2. 自定义转场动画

```dart
// 使用内置转场动画
CustomRoute(
 page: SplashRoute.page,
 path: '/splash',
 transitionsBuilder: TransitionsBuilders.fadeIn, // 淡入
 duration: const Duration(milliseconds: 400),
),

CustomRoute(
 page: LoginRoute.page,
 path: '/login',
 transitionsBuilder: TransitionsBuilders.slideLeft, // 左滑
 duration: const Duration(milliseconds: 300),
),

CustomRoute(
 page: SettingsRoute.page,
 path: '/settings',
 transitionsBuilder: TransitionsBuilders.slideBottom, // 底部弹出
 duration: const Duration(milliseconds: 350),
),
```

**可用的转场类型**:

- `TransitionsBuilders.fadeIn` - 淡入淡出
- `TransitionsBuilders.slideLeft` - 左滑
- `TransitionsBuilders.slideRight` - 右滑
- `TransitionsBuilders.slideTop` - 上滑
- `TransitionsBuilders.slideBottom` - 下滑
- `TransitionsBuilders.zoomIn` - 缩放

### 3. 路由守卫

详细信息请参考 [路由守卫](#路由守卫) 章节。

## 路由守卫

### 1. AuthGuard - 认证守卫

**文件位置**: `lib/core/router/guards/auth_guard.dart`

**功能**: 检查用户是否已登录，未登录则重定向到登录页。

```dart
@singleton
class AuthGuard extends AutoRouteGuard {
 AuthGuard(this._authRepository);

 final AuthRepository _authRepository;

 @override
 Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
 final routeName = resolver.route.name;

 try {
 // 检查用户是否已登录
 final isAuthenticated = await _authRepository.isUserLoggedIn();

 if (isAuthenticated) {
 // 已登录，允许访问
 resolver.next();
 } else {
 // 未登录，重定向到登录页
 AppLogger.info('用户未登录，重定向到登录页');
 resolver.redirectUntil(
 LoginRoute(
 onResult: ({bool success = false}) {
 // 如果登录成功，恢复导航；否则中止
 resolver.next(success);
 },
 ),
 );
 }
 } catch (e, stackTrace) {
 AppLogger.error('认证检查失败', error: e, stackTrace: stackTrace);
 resolver.redirectUntil(LoginRoute());
 }
 }
}
```

### 2. DebouncerGuard - 防抖守卫

**文件位置**: `lib/core/router/guards/debouncer_guard.dart`

**功能**: 防止用户快速连续导航到同一个路由（500ms 防抖窗口）。

```dart
@singleton
class DebouncerGuard extends AutoRouteGuard {
 @override
 void onNavigation(NavigationResolver resolver, StackRouter router) {
 final routeName = resolver.route.name;

 // 检查是否应该阻止导航
 if (!NavigationDebouncer.instance.canNavigate(routeName)) {
 // 阻止导航
 return;
 }

 // 允许导航
 resolver.next();
 }
}
```

**NavigationDebouncer 实现**:

```dart
class NavigationDebouncer {
 static final NavigationDebouncer instance = NavigationDebouncer._();
 NavigationDebouncer._();

 final Map<String, int> _lastNavigationTimes = {};
 static const int debounceWindowMs = 500; // 防抖窗口时间

 bool canNavigate(String path, {int? debounceWindowMs}) {
 final now = DateTime.now().millisecondsSinceEpoch;
 final lastTime = _lastNavigationTimes[path];
 final windowMs = debounceWindowMs ?? NavigationDebouncer.debounceWindowMs;

 // 检查是否在防抖窗口内
 if (lastTime != null && (now - lastTime) < windowMs) {
 AppLogger.warning(
 '导航防抖: 忽略快速点击 -> $path (时间差: ${now - lastTime}ms)',
 );
 return false;
 }

 // 更新最后导航时间
 _lastNavigationTimes[path] = now;
 return true;
 }
}
```

### 3. 全局守卫配置

在 `AppRouter` 中应用全局守卫：

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
 // ...

 @override
 List<AutoRouteGuard> get guards => [debouncerGuard, authGuard];
}
```

**守卫执行顺序**:
1. `DebouncerGuard` - 先检查防抖
2. `AuthGuard` - 再检查认证

这样可以避免在防抖期内进行不必要的认证检查。

### 4. 路由级守卫

如果只想为特定路由应用守卫（不推荐，建议使用全局守卫）：

```dart
AutoRoute(
 page: OrderDetailRoute.page,
 path: '/order-detail/:orderId',
 guards: [authGuard, debouncerGuard], // 路由级守卫
),
```

## 最佳实践

### 1. 页面注解

✅ **推荐**:

```dart
@RoutePage()
class HomePage extends StatelessWidget {
 const HomePage({super.key});
 // ...
}
```

❌ **不推荐**:

```dart
// 缺少 @RoutePage() 注解
class HomePage extends StatelessWidget {
 const HomePage({super.key});
 // ...
}
```

### 2. 参数传递

✅ **推荐**:

```dart
// 使用类型安全的参数
@RoutePage()
class OrderDetailPage extends StatelessWidget {
 const OrderDetailPage({
 @PathParam('orderId') required this.orderId,
 super.key,
 });

 final String orderId;
 // ...
}

// 导航时传递参数
context.router.push(ExampleDetailRoute(orderId: '123'));
```

❌ **不推荐**:

```dart
// 使用动态类型或字符串拼接
context.push('/order-detail?orderId=123');
```

### 3. 导航方式

✅ **推荐**:

```dart
// 使用生成的路由类
context.router.push(const HomeRoute());

// 防抖导航已自动处理
context.router.push(const OrderDetailRoute(orderId: '123'));
```

❌ **不推荐**:

```dart
// 使用字符串路径（不类型安全）
context.push('/home');

// 手动实现防抖（已由 DebouncerGuard 处理）
if (canNavigate) {
 context.router.push(const OrderDetailRoute(orderId: '123'));
}
```

### 4. 代码生成

✅ **推荐**:

```bash
# 开发时使用 watch 模式
dart run build_runner watch --delete-conflicting-outputs

# 构建时使用 build 模式
dart run build_runner build --delete-conflicting-outputs
```

❌ **不推荐**:

```bash
# 不使用 --delete-conflicting-outputs
dart run build_runner build # 可能导致冲突
```

### 5. 路由命名

✅ **推荐**:

```dart
// 使用清晰、描述性的路径
AutoRoute(
 page: ExampleDetailRoute.page,
 path: '/order-detail/:orderId',
),

AutoRoute(
 page: ExampleStatsDetailRoute.page,
 path: '/service-order-stats-detail/:statsType',
),
```

❌ **不推荐**:

```dart
// 使用缩写或不清晰的路径
AutoRoute(
 page: OrderDetailRoute.page,
 path: '/od/:id', // 不清晰
),
```

## 常见问题

### Q1: 导航没有反应？

**可能原因**:

1. **页面缺少 `@RoutePage()` 注解**
2. **未运行代码生成**
3. **路由守卫拦截**
4. **防抖拦截**（500ms 内重复导航）

**解决方案**:

```dart
// 1. 确保页面有注解
@RoutePage()
class MyPage extends StatelessWidget { }

// 2. 运行代码生成
dart run build_runner build --delete-conflicting-outputs

// 3. 检查日志
// 查看是否有守卫拦截信息

// 4. 等待防抖窗口期结束（500ms）
```

### Q2: 如何传递复杂对象？

**方案一：使用 extra 参数**（推荐用于临时数据）

```dart
// 定义路由接收 extra
@RoutePage()
class OrderDetailPage extends StatelessWidget {
 const OrderDetailPage({
 @PathParam('orderId') required this.orderId,
 @queryParam extra, // 接收 extra
 super.key,
 });

 final String orderId;
 // ...
}

// 传递对象
final order = OrderModel(...);
context.router.push(
 ExampleDetailRoute(orderId: order.id),
 // extra: order, // auto_route 10.x 版本支持
);
```

**方案二：使用状态管理**（推荐用于持久数据）

```dart
// 使用 Riverpod Provider 共享数据
final selectedOrderProvider = StateProvider<OrderModel?>((ref) => null);

// 设置数据
ref.read(selectedOrderProvider.notifier).state = order;

// 导航
context.router.push(OrderDetailRoute(orderId: order.id));

// 在目标页面读取
final order = ref.watch(selectedOrderProvider);
```

### Q3: 如何禁用防抖？

防抖是在路由守卫层面实现的，建议保留。如果确实需要禁用：

**方案一：调整防抖窗口**

```dart
// 修改 NavigationDebouncer 中的常量
static const int debounceWindowMs = 0; // 禁用防抖
```

**方案二：从全局守卫中移除**

```dart
@override
List<AutoRouteGuard> get guards => [authGuard]; // 不包含 debouncerGuard
```

### Q4: 如何监听路由变化？

**方案一：使用 NavigatorObserver**

```dart
class MyRouteObserver extends NavigatorObserver {
 @override
 void didPush(Route route, Route? previousRoute) {
 super.didPush(route, previousRoute);
 AppLogger.info('Push: ${route.settings.name}');
 }

 @override
 void didPop(Route route, Route? previousRoute) {
 super.didPop(route, previousRoute);
 AppLogger.info('Pop: ${route.settings.name}');
 }
}

// 在 main.dart 中注册
final observer = MyRouteObserver();
routerConfig: appRouter.config(
 navigatorObservers: () => [observer],
),
```

### Q5: 底部导航如何切换标签？

```dart
// 在 AppShell 中
final tabsRouter = AutoTabsRouter.of(context);

// 切换到指定索引
tabsRouter.setActiveIndex(index);

// 获取当前索引
final currentIndex = tabsRouter.activeIndex;
```

### Q6: 如何在没有 BuildContext 的地方导航？

**不推荐在没有 context 的地方导航**，但如果必须：

```dart
// 使用全局 NavigatorKey
class DialogUtils {
 static GlobalKey<NavigatorState>? navigatorKey;

 static BuildContext? get _context => navigatorKey?.currentContext;

 static void showMessage(String message) {
 if (_context != null) {
 // 使用 context
 }
 }
}

// 在 main.dart 中设置
DialogUtils.navigatorKey = GlobalKey<NavigatorState>();
```

## 总结

### 路由系统优势

- ✅ **类型安全**: 编译期检查，避免运行时错误
- ✅ **代码生成**: 自动生成类型安全的路由代码
- ✅ **路由守卫**: 统一的认证和防抖处理
- ✅ **Shell路由**: 完善的底部导航支持
- ✅ **IDE 支持**: 完整的代码提示和重构
- ✅ **易于维护**: 清晰的文件组织和职责分离

### 从 go_router 迁移的优势

| 特性 | go_router（旧） | auto_route（新） |
|------|----------------|------------------|
| 类型检查 | ❌ 运行时 | ✅ 编译期 |
| 参数验证 | ⚠️ 手动 | ✅ 自动 |
| IDE 支持 | ⚠️ 基础 | ✅ 完整 |
| 路由守卫 | ⚠️ Redirect 函数 | ✅ AutoRouteGuard |
| 防抖支持 | ⚠️ 手动实现 | ✅ 内置守卫 |
| 维护成本 | ⚠️ 较高 | ✅ 较低 |

### 相关文档

- [DebouncerGuard 防抖守卫指南](../debouncer-guard.md)
- [路由系统重构记录](../ROUTING_SYSTEM_REFACTORING.md)

---

**Happy Routing with auto_route!** 🎉

*类型安全、简洁高效的路由系统！*
