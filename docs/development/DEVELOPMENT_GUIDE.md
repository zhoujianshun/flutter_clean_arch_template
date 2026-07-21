# 开发指南

本指南将帮助您快速上手项目开发，了解项目结构和开发规范。

## 📋 目录

- [项目结构](#项目结构)
- [开发环境配置](#开发环境配置)
- [编码规范](#编码规范)
- [状态管理](#状态管理)
- [路由导航](#路由导航)
- [网络请求](#网络请求)
- [数据存储](#数据存储)
- [测试指南](#测试指南)
- [性能优化](#性能优化)

## 项目结构

### 核心目录说明

```text
lib/
├── core/                    # 核心基础设施
│   ├── constants/          # 应用常量定义
│   ├── errors/             # 错误和异常处理
│   ├── network/            # 网络配置和API客户端
│   ├── storage/            # 数据存储服务
│   └── utils/              # 工具类和帮助方法
├── features/               # 功能模块（按业务划分）
│   ├── auth/              # 认证模块
│   │   └── presentation/  # UI层
│   │       ├── pages/     # 页面
│   │       └── widgets/   # 组件
│   ├── home/              # 首页模块
│   ├── profile/           # 个人中心模块
│   ├── settings/          # 设置模块
│   │   └── presentation/  # UI层
│   │       └── pages/     # 设置页面
│   ├── onboarding/        # 引导页模块
│   └── app_shell.dart     # 应用外壳（底部导航）
├── shared/                # 共享组件和服务
│   ├── widgets/           # 通用UI组件
│   ├── models/            # 数据模型
│   └── services/          # 共享业务服务
├── config/                # 配置文件
│   ├── routes/            # 路由配置
│   ├── themes/            # 主题配置
│   └── env/               # 环境配置
└── l10n/                  # 国际化文件
```

## 开发环境配置

### 1. IDE配置

推荐使用 VS Code 作为开发IDE，项目已包含相关配置：

```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "[your-flutter-sdk-path]",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

### 2. 必要插件

- Flutter
- Dart
- Flutter Riverpod Snippets
- Flutter Tree
- Awesome Flutter Snippets

### 3. 代码生成

项目使用代码生成来减少样板代码：

```bash
# 生成所有代码
flutter packages pub run build_runner build

# 监听文件变化自动生成
flutter packages pub run build_runner watch

# 清理后重新生成
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 编码规范

### 1. 命名约定

- **文件命名**: 使用蛇形命名法 `snake_case`
- **类命名**: 使用帕斯卡命名法 `PascalCase`
- **变量/方法命名**: 使用驼峰命名法 `camelCase`
- **常量命名**: 使用全大写蛇形命名法 `SCREAMING_SNAKE_CASE`

### 2. 目录组织

```text
feature_name/
├── data/                  # 数据层（如果需要）
│   ├── models/           # 数据模型
│   ├── repositories/     # 数据仓库实现
│   └── data_sources/     # 数据源（API/本地）
├── domain/                # 业务层（如果需要）
│   ├── entities/         # 业务实体
│   └── repositories/     # 数据仓库接口
└── presentation/          # 表现层
    ├── pages/            # 页面
    ├── widgets/          # 组件
    └── providers/        # 状态提供者
```

### 3. 代码注释

```dart
/// 用户数据模型
/// 
/// 包含用户的基本信息和权限设置
class User {
  /// 用户唯一标识符
  final String id;
  
  /// 用户邮箱地址
  final String email;
  
  /// 创建用户实例
  /// 
  /// [id] 用户唯一标识符
  /// [email] 用户邮箱地址
  const User({
    required this.id,
    required this.email,
  });
}
```

## 状态管理

项目使用 Riverpod 进行状态管理，以下是基本使用方法：

**架构约定**：**Provider 统一直接调用 Repository，不使用 UseCase 层**（`getIt<SomeRepository>()`）。参数校验、请求组装等业务逻辑内联在 Provider 中。

### 1. Provider定义

```dart
// 简单状态
final counterProvider = StateProvider<int>((ref) => 0);

// 异步状态（直调 Repository，与项目当前实践一致）
final currentUserProvider = FutureProvider<User?>((ref) async {
  final repository = getIt<AuthRepository>();
  final result = await repository.getCurrentUser();
  return result.fold((l) => null, (r) => r);
});

// 通知者Provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
```

### 2. 在Widget中使用

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final userAsync = ref.watch(userProvider);
    
    return Column(
      children: [
        Text('Counter: $counter'),
        userAsync.when(
          data: (user) => Text('User: ${user?.name ?? 'Unknown'}'),
          loading: () => CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(counterProvider.notifier).state++;
          },
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

## 路由导航

项目使用 `auto_route ^10.2.0` 实现类型安全的路由导航系统，提供编译期类型检查和自动代码生成。

> 📚 **完整文档**: 请参阅 [路由系统完整指南](../tools-config/ROUTING_SYSTEM_GUIDE.md)

### 1. 路由架构

```dart
路由系统
├── app_router.dart          # 路由配置和定义
├── app_router.gr.dart       # 自动生成的路由代码
├── router_provider.dart     # Riverpod 路由 Provider
├── guards/                  # 路由守卫
│   ├── auth_guard.dart      # 认证守卫
│   └── debouncer_guard.dart # 防抖守卫
└── utils/                   # 路由工具
    └── navigation_debouncer.dart
```

### 2. 完整路由清单

本项目定义了以下路由，详细信息请参阅 [路由系统完整指南](../tools-config/ROUTING_SYSTEM_GUIDE.md)。

**路由分类**：

- 认证路由: 3个（SplashRoute、OnboardingRoute、LoginRoute）
- Shell路由: 4个（AppShellRoute、WorkbenchRoute、NotificationCenterRoute、ProfileRoute）
- 订单路由: 2个（OrderDetailRoute、OrderStatsDetailRoute）
- 通知路由: 1个（AnnouncementDetailRoute）
- 应用路由: 3个（ConfigManagementRoute、LoggerViewerRoute、ThemeSettingsRoute）

**总计**: 13个类型安全路由

### 3. 页面定义（类型安全）

所有页面都需要添加 `@RoutePage()` 注解：

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// 简单页面
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

/// 带路径参数的页面
@RoutePage()
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    @PathParam('orderId') required this.orderId,  // 路径参数
    @QueryParam('showAlert') this.showAlert = false,  // 查询参数
    super.key,
  });

  final String orderId;
  final bool showAlert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('订单 $orderId')),
      body: Center(
        child: Text(showAlert ? '显示提示' : '正常显示'),
      ),
    );
  }
}
```

然后在 `app_router.dart` 中定义路由：

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
    ),
    AutoRoute(
      page: OrderDetailRoute.page,
      path: '/order-detail/:orderId',  // :orderId 是路径参数
    ),
  ];
}
```

### 4. 路由导航（类型安全）

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';

// 推送新页面
context.router.push(const HomeRoute());

// 带参数的导航（编译期类型检查）
context.router.push(
  OrderDetailRoute(
    orderId: '123',
    showAlert: true,
  ),
);

// 替换当前页面
context.router.replace(const LoginRoute());

// 替换所有路由
context.router.replaceAll([const AppShellRoute()]);

// 返回上一页
context.router.pop();

// 返回并传递结果
context.router.pop<String>('result_data');

// 检查是否可以返回
if (context.router.canPop()) {
  context.router.pop();
}

// 获取当前路由
final currentRoute = context.router.current;
```

**优势**:

- ✅ 编译期参数检查
- ✅ IDE 自动补全和重构支持
- ✅ 自动防抖（500ms，通过 DebouncerGuard）
- ✅ 类型安全的参数和返回值

### 5. 路由守卫

项目使用 `AutoRouteGuard` 实现路由守卫：

**AuthGuard - 认证守卫**:

```dart
@singleton
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    // 检查用户是否已登录
    final isAuthenticated = await _authRepository.isUserLoggedIn();

    if (isAuthenticated) {
      resolver.next(); // 允许导航
    } else {
      // 未登录，重定向到登录页
      resolver.redirectUntil(const LoginRoute());
    }
  }
}
```

**DebouncerGuard - 防抖守卫**:

```dart
@singleton
class DebouncerGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final routeName = resolver.route.name;

    // 检查是否应该阻止导航（500ms 防抖窗口）
    if (!NavigationDebouncer.instance.canNavigate(routeName)) {
      return; // 阻止导航
    }

    resolver.next(); // 允许导航
  }
}
```

**全局守卫配置**:

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRouteGuard> get guards => [debouncerGuard, authGuard];
}
```

### 6. 自定义转场动画

使用 `CustomRoute` 定义自定义转场：

```dart
// 启动页 - 淡入动画
CustomRoute(
  page: SplashRoute.page,
  path: '/splash',
  transitionsBuilder: TransitionsBuilders.fadeIn,
  duration: const Duration(milliseconds: 400),
),

// 登录页 - 底部弹出动画
CustomRoute(
  page: LoginRoute.page,
  path: '/auth/login',
  transitionsBuilder: TransitionsBuilders.slideBottom,
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

### 7. 代码生成

每次修改路由后需要运行代码生成：

```bash
# 一次性生成
dart run build_runner build --delete-conflicting-outputs

# 监听模式（开发时推荐）
dart run build_runner watch --delete-conflicting-outputs
```

这会生成 `app_router.gr.dart` 文件，包含所有路由的类型安全代码。

### 8. 底部导航（Shell 路由）

使用 `AutoTabsRouter` 实现底部导航：

```dart
@RoutePage()
class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoTabsRouter(
      routes: [
        const WorkbenchRoute(),
        const NotificationCenterRoute(),
        const ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '工作台'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications), label: '通知'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
            ],
          ),
        );
      },
    );
  }
}
```

### 9. 404 处理

使用 `RedirectRoute` 处理未找到的路由：

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    // ... 其他路由

    // 404 处理 - 重定向到启动页
    RedirectRoute(path: '*', redirectTo: '/splash'),
  ];
}
```

## 网络请求

### 1. API客户端使用

```dart
class UserRepository {
  final ApiClient _apiClient;
  
  UserRepository(this._apiClient);
  
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final response = await _apiClient.get('/users/$id');
      final user = User.fromJson(response.data);
      return Right(user);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

### 2. 错误处理

```dart
final result = await userRepository.getUser('123');
result.fold(
  (failure) {
    // 处理错误
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.message)),
    );
  },
  (user) {
    // 处理成功
    print('User loaded: ${user.name}');
  },
);
```

## 数据存储与缓存

项目当前采用“持久化存储”和“临时缓存”分离架构：

- `StorageService`：管理持久化重要数据（用户数据、设置、Token）
- `CacheService`：管理临时可丢弃数据（API TTL 缓存、图片/文件缓存）

### 1. 架构分层

```dart
/// 持久化存储（不可随意丢失）
final storage = getIt<StorageService>();

/// 临时缓存（可清理、可重拉）
final cache = getIt<CacheService>();
```

### 2. 初始化方式

```dart
// 在 main() 中初始化依赖注入
await ServiceLocator.initialize();

// StorageService / CacheService 会由 DI 自动创建并注册
```

### 3. 持久化数据（StorageService）

```dart
final storage = getIt<StorageService>();

// 用户数据（Hive: user_box）
await storage.setUserData('profile', userModel);
final user = storage.getUserData<UserModel>('profile');
await storage.removeUserData('profile');
await storage.clearUserData();

// 应用设置（SharedPreferences）
await storage.setSetting('theme_mode', 'dark');
final theme = storage.getSetting('theme_mode', defaultValue: 'system');
await storage.removeSetting('theme_mode');

// Token（SecureStorage）
await storage.setUserToken('access_token');
final token = await storage.getUserToken();
await storage.removeUserToken();

await storage.setRefreshToken('refresh_token');
final refresh = await storage.getRefreshToken();
await storage.removeRefreshToken();
```

### 4. 临时缓存（CacheService）

```dart
final cache = getIt<CacheService>();

// API 数据缓存（TTL）
await cache.cacheApiResponse(
  'orders/list',
  responseData,
  ttl: const Duration(minutes: 5),
);
final cachedOrders = cache.getCachedApiResponse<List<dynamic>>('orders/list');

// 通用缓存
await cache.cacheData('dashboard', dashboardData);
final dashboard = cache.getCachedData<Map<String, dynamic>>('dashboard');

// 文件缓存
await cache.cacheAvatar(avatarUrl);
await cache.cacheGeneralImage(imageUrl);
```

### 5. 调试与清理

```dart
final storage = getIt<StorageService>();
final cache = getIt<CacheService>();

// 调试信息
final storageInfo = await storage.getStorageInfo();
final cacheStats = cache.getCacheStats();

// 清理策略
await storage.clearUserData();        // 清用户持久数据
await cache.clearExpiredCache();      // 清过期缓存
await cache.clearAllCache();          // 清所有缓存（不影响核心功能）
```

### 6. 选择建议

| 数据类型 | 推荐服务 | 说明 |
|---------|----------|-----|
| 用户 Token / Refresh Token | `StorageService` | 敏感数据，必须安全存储 |
| 用户资料 | `StorageService` | 持久化重要数据 |
| 主题/语言等设置 | `StorageService` | 启动后仍需保留 |
| API 响应缓存 | `CacheService` | 临时数据，允许过期失效 |
| 图片/文件缓存 | `CacheService` | 可随时清理，按需重拉 |
| 临时页面数据 | `CacheService` | 丢失不影响核心流程 |

## 测试指南

### 1. 单元测试

```dart
void main() {
  group('Validators', () {
    test('should validate email correctly', () {
      expect(Validators.isEmail('test@example.com'), true);
      expect(Validators.isEmail('invalid'), false);
    });
  });
}
```

### 2. Widget测试

```dart
void main() {
  testWidgets('LoadingButton shows loading indicator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadingButton(
          isLoading: true,
          onPressed: () {},
          child: Text('Test'),
        ),
      ),
    );
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### 3. 集成测试

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('full app test', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // 测试应用流程
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

## 性能优化

### 1. 图片优化

```dart
// 使用缓存图片组件
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(height: 200, color: Colors.white),
  ),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### 2. 列表优化

```dart
// 使用ListView.builder构建大列表
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index].title),
    );
  },
)
```

### 3. 状态优化

```dart
// 使用select避免不必要的重建
Widget build(BuildContext context, WidgetRef ref) {
  final userName = ref.watch(userProvider.select((user) => user?.name));
  return Text(userName ?? 'Unknown');
}
```

## 常用命令

```bash
# 运行应用
flutter run

# 构建APK
flutter build apk

# 构建iOS
flutter build ios

# 运行测试
flutter test

# 分析代码
flutter analyze

# 格式化代码
dart format lib/

# 清理项目
flutter clean
```

## 开发技巧

### 1. 快速导航

- `Cmd/Ctrl + P`: 快速打开文件
- `Cmd/Ctrl + Shift + P`: 命令面板
- `F12`: 跳转到定义
- `Shift + F12`: 查找引用

### 2. 调试技巧

- 使用 `debugPrint()` 代替 `print()`
- 使用 Flutter Inspector 调试UI
- 使用断点调试代码逻辑
- 使用 `AppLogger` 记录重要信息

### 3. 代码片段

项目提供了常用的代码片段模版，输入以下前缀快速生成代码：

- `stless`: StatelessWidget模版
- `stful`: StatefulWidget模版
- `provider`: Riverpod Provider模版
- `cubit`: Cubit模版

---

有问题欢迎提出Issue或贡献代码！
