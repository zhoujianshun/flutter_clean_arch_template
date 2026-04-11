# Provider 组织架构最佳实践指南

## 📖 概述

本文档详细说明如何在 Flutter + Riverpod 项目中组织不同层次的 Provider，确保代码的可维护性、可扩展性和团队协作效率。

> **⚠️ Freezed 3.0+ 说明**：文档中的 Freezed 示例已更新为使用 `abstract class`（单一数据类）。详见 [FREEZED_SEALED_VS_ABSTRACT.md](../architecture/FREEZED_SEALED_VS_ABSTRACT.md)

## 🏗️ Provider 层次架构

### 1. 架构层次图

```
Application Layer
├── 项目级 Provider (Global/App-level)
│   ├── 基础设施 Provider (Infrastructure)
│   ├── 核心业务 Provider (Core Business)
│   └── 应用配置 Provider (App Configuration)
│
├── 功能级 Provider (Feature-level)
│   ├── 跨页面共享状态
│   └── 功能模块业务逻辑
│
└── 页面级 Provider (Page-level)
    ├── 页面特定状态
    ├── 表单状态
    └── UI 交互状态
```

### 2. 目录结构组织

项目采用 **Feature-First** 架构，所有 Provider 位于各功能模块的 `presentation/providers/` 目录下：

```
lib/
├── app/
│   ├── di/
│   │   └── service_locator.dart          # GetIt 配置 (getIt 全局实例)
│   ├── themes/
│   │   └── theme_mode_provider.dart      # 主题模式 (传统 NotifierProvider)
│   ├── language/
│   │   └── language_provider.dart        # 语言配置 (传统 NotifierProvider)
│   └── routes/
│       └── guards/auth_guard.dart        # 路由守卫（使用 authProvider）
│
├── features/
│   ├── app/presentation/providers/       # 应用级 Provider
│   │   ├── app_info_provider.dart
│   │   ├── app_shell_tab_index_provider.dart
│   │   └── privacy_policy_provider.dart
│   │
│   ├── auth/presentation/providers/      # 认证模块 Provider
│   │   ├── auth_provider.dart            # @Riverpod(keepAlive: true) Auth
│   │   └── models/
│   │       └── auth_state.dart           # Freezed AuthState
│   │
│   ├── notification/presentation/providers/  # 消息中心 Provider
│   │   ├── announcement_detail_provider.dart
│   │   ├── notification_provider.dart
│   │   └── unread_message_provider.dart
│   │
│   └── order/presentation/providers/   # 订单模块 Provider
│       ├── actions/                      # 订单操作相关
│       │   ├── accept_order_provider.dart
│       │   ├── reject_order_provider.dart
│       │   ├── order_sign_in_provider.dart
│       │   └── submit_care_record_provider.dart
│       ├── order_detail/                 # 订单详情相关
│       │   ├── order_detail_provider.dart
│       │   └── order_detail_comment_provider.dart
│       ├── workbench/                    # 工作台相关
│       │   ├── workbench_filter_provider.dart
│       │   ├── workbench_tab_provider.dart
│       │   └── workbench_tab_refresh_provider.dart
│       ├── order_stats/          # 服务统计相关
│       │   ├── service_stats_provider.dart
│       │   └── order_stats_detail_provider.dart
│       ├── order_list_provider.dart
│       ├── order_countdown_provider.dart
│       ├── order_delete_notification_provider.dart
│       └── pending_accept_notification_provider.dart
│
└── shared/                               # 跨功能共享代码（无 Provider）
    ├── network/
    ├── storage/
    └── ...
```

> **注意**：项目不使用集中式 `lib/providers/` 或 `lib/di/providers.dart` 目录。
> 业务服务通过 `getIt<>()` (GetIt) 直接获取，无需桥接 Provider。

## 🎯 Provider 分类详解

### 1. 项目级 Provider (Global/App-level)

**特点**：

- 整个应用生命周期内存在
- 跨多个页面和功能模块使用
- 通常使用 `@Riverpod(keepAlive: true)` 保持存活

#### A. 基础设施服务（通过 GetIt 直接获取）

项目中基础设施服务**不通过 Riverpod Provider** 桥接，而是直接使用 GetIt：

```dart
// lib/core/di/service_locator.dart
final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();

// 在任意位置直接获取服务
final apiClient = getIt<ApiClient>();
final storageService = getIt<StorageService>();
final tokenManager = getIt<TokenManager>();
```

**职责**：

- GetIt 负责管理所有基础设施和业务服务的生命周期
- Riverpod 专注于 UI 状态管理，不承担依赖注入职责
- Provider 中通过 `getIt<>()` 获取所需服务

#### B. 核心业务 Provider

```dart
// lib/features/auth/presentation/providers/auth_provider.dart
/// 认证状态 - 全应用共享，keepAlive 保证应用生命周期内持续存活
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = getIt<AuthRepository>();
    _listenToAuthEvents();
    unawaited(_initializeAuth());
    return const AuthState(isLoading: true);
  }
  // Provider 统一直接调用 Repository，不使用 UseCase 层：
  // 登录在 phoneLogin 内联校验与组装 PhoneLoginRequest 后调用 _authRepository.phoneLogin；
  // 本地恢复 / 用户信息 / 登出等同样直接调用 _authRepository
}

// lib/features/app/presentation/providers/app_info_provider.dart
/// 应用信息 Provider
@riverpod
class AppInfo extends _$AppInfo {
  @override
  Future<Map<String, String>> build() async {
    final appInfoService = getIt<AppInfoService>();
    return appInfoService.getAppInfo();
  }
}
```

**特点**：

- 使用 `@Riverpod(keepAlive: true)` 保持全局状态
- 通过 `getIt<>()` 获取 **Repository** 及各类 Service；**Provider 统一直接调用 Repository，不使用 UseCase 层**
- 跨多个页面使用

#### C. 应用配置 Provider

```dart
// lib/core/theme/theme_mode_provider.dart
/// 主题模式 - 使用 @Riverpod(keepAlive: true)
/// 生成的 Provider: appThemeModeProvider
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() => ThemeMode.light;
  
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemeMode(mode);
  }
}

// lib/core/l10n/language_provider.dart
/// 语言配置 - 使用 @Riverpod(keepAlive: true)
/// 生成的 Provider: appLanguageSettingProvider
@Riverpod(keepAlive: true)
class AppLanguageSetting extends _$AppLanguageSetting {
  @override
  AppLanguage build() => AppLanguage.chinese;
  
  Future<void> changeLanguage(AppLanguage language) async {
    state = language;
    await LanguageService.saveLanguage(language);
  }
}

/// 当前 Locale - 派生自语言设置
/// 生成的 Provider: appLocaleProvider
@Riverpod(keepAlive: true)
Locale appLocale(Ref ref) {
  final language = ref.watch(appLanguageSettingProvider);
  return language.locale;
}
```

### 2. 功能级 Provider (Feature-level)

**特点**：

- 特定功能模块内使用
- 可能跨该功能的多个页面
- 根据需要决定是否保持存活

#### 示例：购物车功能

```dart
// lib/features/shopping/providers/cart_provider.dart
@Riverpod(keepAlive: true)  // 购物车状态需要跨页面保持
class ShoppingCart extends _$ShoppingCart {
  @override
  CartState build() {
    return const CartState(items: []);
  }
  
  void addItem(Product product) {
    // 添加商品逻辑...
  }
}

// lib/features/shopping/providers/product_list_provider.dart
@riverpod  // 商品列表可以自动销毁
class ProductList extends _$ProductList {
  @override
  Future<List<Product>> build() async {
    // 获取商品列表...
  }
}
```

### 3. 页面级 Provider (Page-level)

**特点**：

- 只在特定页面使用
- 页面销毁时自动清理
- 通常不使用 `keepAlive`

#### A. 表单状态 Provider

```dart
// lib/features/pages/profile/providers/profile_form_provider.dart
@freezed
abstract class ProfileFormState with _$ProfileFormState {
  const factory ProfileFormState({
    @Default('') String name,
    @Default('') String email,
    @Default('') String phone,
    @Default(false) bool isLoading,
    @Default({}) Map<String, String> errors,
  }) = _ProfileFormState;
}

@riverpod  // 页面级，不需要 keepAlive
class ProfileForm extends _$ProfileForm {
  @override
  ProfileFormState build() {
    return const ProfileFormState();
  }
  
  void updateName(String name) {
    state = state.copyWith(name: name);
  }
  
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }
  
  Future<void> submit() async {
    // 提交表单逻辑...
  }
}
```

#### B. UI 交互状态 Provider

```dart
// lib/features/pages/home/providers/home_ui_provider.dart
@freezed
abstract class HomeUIState with _$HomeUIState {
  const factory HomeUIState({
    @Default(0) int selectedTabIndex,
    @Default(false) bool isRefreshing,
    @Default(false) bool showFloatingButton,
  }) = _HomeUIState;
}

@riverpod
class HomeUI extends _$HomeUI {
  @override
  HomeUIState build() {
    return const HomeUIState();
  }
  
  void selectTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
  
  void setRefreshing(bool isRefreshing) {
    state = state.copyWith(isRefreshing: isRefreshing);
  }
}
```

#### C. 页面数据 Provider

```dart
// lib/features/pages/profile/providers/service_stats_provider.dart
@riverpod
class ServiceStats extends _$ServiceStats {
  @override
  Future<List<ServiceStatsData>> build() async {
    // 设置默认数据，优化用户体验
    state = const AsyncValue.data([
      ServiceStatsData(serviceCount: 0, description: '待服务'),
      ServiceStatsData(serviceCount: 0, description: '本月已服务'),
      ServiceStatsData(serviceCount: 0, description: '累计已服务'),
    ]);
    
    return _loadServiceStats();
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadServiceStats);
  }
}
```

## 🔄 Provider 间的依赖关系

### 1. 依赖层次

```
页面级 Provider
    ↓ 依赖
功能级 Provider
    ↓ 依赖
项目级 Provider
    ↓ 依赖
基础设施 Provider
```

### 2. 依赖示例

```dart
// 页面级 Provider 依赖功能级 Provider
@riverpod
class ProfilePage extends _$ProfilePage {
  @override
  ProfilePageState build() {
    // 依赖认证状态（通过 ref.watch 监听）
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return const ProfilePageState.unauthenticated();
    }
    
    return ProfilePageState.authenticated(user: authState.user!);
  }
}

// 功能级 Provider 使用 GetIt 获取 Repository（简单场景直接调仓储）
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<CurrentUserInfoModel> build() async {
    final repository = getIt<AuthRepository>();
    final result = await repository.getCurrentUser();
    return result.fold(
      (failure) => throw failure,
      (user) => user,
    );
  }
}
```

## 📱 实际应用示例

### 1. 项目当前结构分析

**现状**（Feature-First 架构）：

```
lib/features/
├── auth/presentation/providers/
│   ├── auth_provider.dart              # ✅ 项目级 - 认证状态 (keepAlive)
│   └── models/auth_state.dart          # ✅ 认证状态模型
├── app/presentation/providers/
│   ├── app_info_provider.dart          # ✅ 项目级 - 应用信息
│   ├── app_shell_tab_index_provider.dart  # ✅ 项目级 - Tab 状态
│   └── privacy_policy_provider.dart    # ✅ 项目级 - 隐私政策
├── order/presentation/providers/
│   ├── order_list_provider.dart        # ✅ 功能级 - 订单列表
│   ├── actions/accept_order_provider.dart  # ✅ 页面级 - 接单操作
│   └── order_stats/service_stats_provider.dart  # ✅ 页面级 - 统计
└── notification/presentation/providers/
    ├── notification_provider.dart    # ✅ 功能级 - 消息中心
    └── unread_message_provider.dart    # ✅ 功能级 - 未读计数
```

**结构特点**：每个功能模块自包含，Provider 按功能域分组，通过子目录（如 `actions/`、`workbench/`）进一步细分。

### 2. 实际 Provider 示例

```dart
// lib/features/order/presentation/providers/order_stats/service_stats_provider.dart
@riverpod
class ServiceStats extends _$ServiceStats {
  @override
  Future<List<ServiceStatsData>> build() async {
    // 先设置默认数据避免页面闪烁
    state = const AsyncValue.data([
      ServiceStatsData(serviceCount: 0, description: '待服务'),
      ServiceStatsData(serviceCount: 0, description: '本月已服务'),  
      ServiceStatsData(serviceCount: 0, description: '累计已服务'),
    ]);
    
    return _loadServiceStats();
  }
}

// lib/features/app/presentation/providers/app_shell_tab_index_provider.dart
// 标签页状态保持在应用级
@Riverpod(keepAlive: true)
class AppShellTabIndex extends _$AppShellTabIndex {
  @override
  int build() => 0;
  
  void setIndex(int index) {
    state = index;
  }
}
```

## 🎯 最佳实践总结

### 1. 命名约定

```dart
// 项目级 Provider - 使用 keepAlive
@Riverpod(keepAlive: true)
class GlobalAuth extends _$GlobalAuth { }

// 功能级 Provider - 根据需要决定
@Riverpod(keepAlive: true)  // 如果需要跨页面保持
class FeatureCart extends _$FeatureCart { }

// 页面级 Provider - 通常不使用 keepAlive
@riverpod
class PageForm extends _$PageForm { }
```

### 2. 文件组织

- **项目级**：`lib/features/{feature}/presentation/providers/`（使用 `keepAlive`）
- **功能级**：`lib/features/{feature}/presentation/providers/`
- **页面/操作级**：`lib/features/{feature}/presentation/providers/{子目录}/`（如 `actions/`、`workbench/`）
- **应用配置**：`lib/core/theme/`、`lib/core/l10n/`

### 3. 生命周期管理

```dart
// 项目级 - 长期存活
@Riverpod(keepAlive: true)
class AppTheme extends _$AppTheme { }

// 页面级 - 自动销毁
@riverpod
class PageData extends _$PageData { }

// 条件保持存活
@riverpod
class ConditionalData extends _$ConditionalData {
  @override
  String build() {
    // 根据条件决定是否保持存活
    if (someCondition) {
      ref.keepAlive();
    }
    return 'data';
  }
}
```

### 4. 依赖注入最佳实践

```dart
// ✅ 推荐：通过 GetIt (getIt) 获取 Repository；业务逻辑（校验、组装请求等）写在 Provider 内
@riverpod
class UserData extends _$UserData {
  @override
  Future<CurrentUserInfoModel> build() async {
    final repository = getIt<AuthRepository>();
    final result = await repository.getCurrentUser();
    return result.fold(
      (failure) => throw failure,
      (user) => user,
    );
  }
}

// ❌ 避免：通过 Riverpod Provider 管理服务实例
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl();  // 不推荐 - 服务管理应交给 GetIt
}
```

## 🚀 项目优化建议

基于当前项目结构，以下待优化事项：

1. **迁移传统 Provider 到 @riverpod 注解**：
   - `theme_mode_provider.dart` — 仍使用传统 `NotifierProvider`
   - `language_provider.dart` — 仍使用传统 `NotifierProvider`

2. **保持 Feature-First 结构一致性**：
   - 新增功能模块时，Provider 统一放在 `lib/features/{feature}/presentation/providers/` 下
   - 复杂模块使用子目录（如 `actions/`、`workbench/`）细分

3. **UX 最佳实践**：
   - 使用 `AsyncValue.data()` 先设置默认数据，避免页面闪烁
   - 在加载和错误状态下保留现有数据显示
