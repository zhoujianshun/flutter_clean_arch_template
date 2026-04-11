# Riverpod 完整使用指南

## 📖 概述

本文档是 Flutter Riverpod 的完整使用指南，涵盖从基础概念到高级应用的所有内容。包含 Riverpod 3.0+ 的最新 API、AsyncValue 详细用法，以及生产环境中的最佳实践案例。

> **⚠️ Freezed 3.0+ 重要说明**：本文档中的 Freezed 代码示例已更新：
>
> - **联合类型**（如 AppError）使用 `sealed class`
> - **单一数据类**（如 AuthState）使用 `abstract class`
> - 详细说明：[FREEZED_SEALED_VS_ABSTRACT.md](../architecture/FREEZED_SEALED_VS_ABSTRACT.md)

## 🎯 目录

1. [Riverpod 基础概念](#riverpod-基础概念)
2. [核心 Provider 类型](#核心-provider-类型)
3. [AsyncValue 完整指南](#asyncvalue-完整指南)
4. [Consumer 和 Ref 使用](#consumer-和-ref-使用)
5. [状态管理最佳实践](#状态管理最佳实践)
6. [错误处理和用户体验](#错误处理和用户体验)
7. [性能优化技巧](#性能优化技巧)
8. [测试策略](#测试策略)
9. [实际项目案例](#实际项目案例)

## Riverpod 基础概念

### 什么是 Riverpod？

Riverpod 是 Flutter 的状态管理解决方案，提供：

- **类型安全**：编译时错误检查
- **可测试性**：方便的单元测试
- **性能优化**：自动重建优化
- **开发体验**：优秀的开发工具支持

### Riverpod 3.0+ 新特性

- 🆕 `@riverpod` 注解语法
- 🆕 `Notifier` 类替代 `StateNotifier`
- 🆕 更好的类型推断
- 🆕 改进的开发者工具

## 核心 Provider 类型

### 1. Provider - 只读数据

用于提供不变的数据或计算结果。

```dart
// 使用 @riverpod 注解（推荐）
@riverpod
String appName(Ref ref) => 'Your App Name';

// 计算属性
@riverpod
String welcomeMessage(Ref ref) {
  final name = ref.watch(userNameProvider);
  return 'Welcome, $name!';
}

// 传统方式（向后兼容）
final configProvider = Provider<AppConfig>((ref) => AppConfig());
```

### 2. Notifier - 可变状态（推荐方式）

用于管理可变状态，替代 StateProvider 和 StateNotifierProvider。

```dart
// 简单状态管理
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;
  
  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

// 复杂状态管理（使用 Freezed - 单一数据容器）
@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    User? user,
    @Default(false) bool isLoading,
    String? error,
  }) = _UserState;
}

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  UserState build() => const UserState();
  
  Future<void> loadUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = getIt<AuthRepository>();
      final result = await repository.getCurrentUser();
      result.fold(
        (failure) => state = state.copyWith(error: failure.message, isLoading: false),
        (user) => state = state.copyWith(user: user, isLoading: false),
      );
    } catch (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
    }
  }
  
  void logout() {
    state = const UserState();
  }
}
```

### 3. FutureProvider - 异步数据

```dart
// 使用 @riverpod 注解
@riverpod
Future<User> currentUser(Ref ref) async {
  final repository = getIt<AuthRepository>();
  final result = await repository.getCurrentUser();

  return result.fold(
    (failure) => throw failure,
    (user) => user,
  );
}

// 带参数的异步 Provider
@riverpod
Future<List<Order>> userOrders(Ref ref, String userId) async {
  final orderService = getIt<OrderService>();
  return orderService.getUserOrders(userId);
}
```

### 4. StreamProvider - 流数据

```dart
@riverpod
Stream<List<Message>> messageStream(Ref ref) {
  return FirebaseFirestore.instance
      .collection('messages')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList());
}
```

## AsyncValue 完整指南

### 核心概念

AsyncValue 是 Riverpod 中处理异步状态的核心类，将异步操作的三种状态封装在一起：

```dart
sealed class AsyncValue<T> {
  const AsyncLoading();           // 加载中
  const AsyncData<T>(T value);    // 成功，包含数据
  const AsyncError(Object error, StackTrace stackTrace); // 失败
}
```

### 基础使用模式

#### 1. when() - 处理所有状态

```dart
class UserProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    
    return userAsync.when(
      data: (user) => UserProfileWidget(user: user),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorWidget(
        error: error.toString(),
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
    );
  }
}
```

#### 2. maybeWhen() - 保留之前数据的处理

```dart
class UserListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);
    
    return Column(
      children: [
        // 刷新指示器
        if (usersAsync.isLoading) 
          const LinearProgressIndicator(),
        
        // 用户列表
        Expanded(
          child: usersAsync.maybeWhen(
            data: (users) => ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) => UserTile(users[index]),
            ),
            orElse: () => usersAsync.hasValue 
                ? ListView.builder(
                    itemCount: usersAsync.value!.length,
                    itemBuilder: (context, index) => 
                        UserTile(usersAsync.value![index]),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
```

### 高级 AsyncValue 模式

#### 1. 分页加载模式

```dart
@freezed
abstract class PaginatedState<T> with _$PaginatedState<T> {
  const factory PaginatedState({
    @Default([]) List<T> items,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMore,
    String? error,
  }) = _PaginatedState<T>;
}

@riverpod
class PaginatedUserList extends _$PaginatedUserList {
  @override
  AsyncValue<PaginatedState<User>> build() {
    return const AsyncValue.data(PaginatedState());
  }

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final users = await _loadUsers(page: 1);
      state = AsyncValue.data(PaginatedState(
        items: users,
        hasMore: users.length >= 20,
      ));
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));
    
    try {
      final page = (currentState.items.length / 20).ceil() + 1;
      final newUsers = await _loadUsers(page: page);
      
      state = AsyncValue.data(currentState.copyWith(
        items: [...currentState.items, ...newUsers],
        isLoadingMore: false,
        hasMore: newUsers.length >= 20,
      ));
    } catch (error) {
      state = AsyncValue.data(currentState.copyWith(
        isLoadingMore: false,
        error: error.toString(),
      ));
    }
  }
}
```

#### 2. 搜索功能模式

```dart
@riverpod
class SearchNotifier extends _$SearchNotifier {
  Timer? _debounceTimer;
  
  @override
  AsyncValue<List<SearchResult>> build() {
    return const AsyncValue.data([]);
  }

  void search(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    // 防抖处理
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    state = const AsyncValue.loading();
    
    try {
      final results = await _searchService.search(query);
      state = AsyncValue.data(results);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const AsyncValue.data([]);
  }
}
```

#### 3. 实时数据同步模式

```dart
@riverpod
class RealTimeOrderList extends _$RealTimeOrderList {
  StreamSubscription? _subscription;
  
  @override
  AsyncValue<List<Order>> build() {
    _setupRealTimeSync();
    return const AsyncValue.loading();
  }

  void _setupRealTimeSync() {
    _subscription?.cancel();
    _subscription = _orderService.getOrderStream().listen(
      (orders) {
        state = AsyncValue.data(orders);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## Consumer 和 Ref 使用

### Consumer 类型

#### 1. ConsumerWidget - 最常用

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}
```

#### 2. Consumer Builder - 在 StatelessWidget 中使用

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final count = ref.watch(counterProvider);
        return Text('Count: $count');
      },
    );
  }
}
```

#### 3. ConsumerStatefulWidget - 有状态 Widget

```dart
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}
```

### Ref 方法详解

#### ref.watch() - 监听变化

```dart
// 监听整个状态
final user = ref.watch(userProvider);

// 监听状态的一部分（性能优化）
final userName = ref.watch(userProvider.select((user) => user?.name));

// 监听异步状态
final userAsync = ref.watch(currentUserProvider);
```

#### ref.read() - 一次性读取

```dart
// 在事件处理中使用
onPressed: () {
  final counter = ref.read(counterProvider.notifier);
  counter.increment();
}

// 在异步方法中使用
Future<void> saveData() async {
  final user = ref.read(userProvider);
  await _saveUser(user);
}
```

#### ref.listen() - 监听副作用

```dart
@override
Widget build(BuildContext context) {
  // 监听状态变化，执行副作用
  ref.listen<AsyncValue<User>>(
    currentUserProvider,
    (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      );
    },
  );
  
  return const Scaffold(/* ... */);
}
```

#### ref.invalidate() - 刷新数据

```dart
// 刷新单个 Provider
ref.invalidate(userListProvider);

// 刷新多个相关 Provider
ref.invalidate(userListProvider);
ref.invalidate(userCountProvider);
```

## 状态管理最佳实践

### 1. 状态设计原则

#### 保持状态扁平化

```dart
// ❌ 避免深层嵌套
@freezed
abstract class BadAppState with _$BadAppState {
  const factory BadAppState({
    Map<String, Map<String, dynamic>>? data,
  }) = _BadAppState;
}

// ✅ 扁平化状态
@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    User? user,
    @Default(false) bool isLoading,
    String? error,
  }) = _UserState;
}
```

#### 单一数据源

```dart
// ✅ 用户信息统一管理
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  UserState build() => const UserState();
  
  // 所有用户状态变更都通过这里
}

// ✅ 派生状态
@riverpod
bool isLoggedIn(Ref ref) {
  return ref.watch(userNotifierProvider).user != null;
}

@riverpod
String? userDisplayName(Ref ref) {
  final user = ref.watch(userNotifierProvider).user;
  return user?.name ?? user?.email;
}
```

### 2. Provider 生命周期管理

#### 自动销毁 vs 保持活跃

```dart
// 自动销毁（默认）- 适用于页面级状态
@riverpod
class PageCounter extends _$PageCounter {
  @override
  int build() => 0;
  // 页面销毁时自动清理
}

// 保持活跃 - 适用于全局状态
@Riverpod(keepAlive: true)
class GlobalUser extends _$GlobalUser {
  @override
  UserState build() => const UserState();
  // 应用生命周期内保持活跃
}
```

#### 手动生命周期控制

```dart
@riverpod
class TimerNotifier extends _$TimerNotifier {
  Timer? _timer;
  
  @override
  int build() {
    // 初始化时启动定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state++;
    });
    
    // 清理资源
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return 0;
  }
}
```

### 3. 错误处理策略

#### 统一错误处理

```dart
// 自定义错误类型 - 联合类型，使用 sealed class
@freezed
sealed class AppError with _$AppError {
  const factory AppError.network(String message) = NetworkError;
  const factory AppError.validation(String field, String message) = ValidationError;
  const factory AppError.unknown(String message) = UnknownError;
}

// 错误处理 Mixin
mixin ErrorHandlerMixin on Notifier {
  void handleError(Object error, StackTrace stack, {String? context}) {
    final appError = _mapToAppError(error);
    
    // 记录错误
    logger.error('Error in ${context ?? runtimeType}', appError, stack);
    
    // 设置错误状态
    if (this is AsyncNotifier) {
      (this as AsyncNotifier).state = AsyncValue.error(appError, stack);
    }
  }
  
  AppError _mapToAppError(Object error) {
    return switch (error) {
      NetworkException e => AppError.network(e.message),
      ValidationException e => AppError.validation(e.field, e.message),
      _ => AppError.unknown(error.toString()),
    };
  }
}

// 使用错误处理
@riverpod
class UserNotifier extends _$UserNotifier with ErrorHandlerMixin {
  @override
  AsyncValue<User> build() => const AsyncValue.loading();
  
  Future<void> loadUser(String id) async {
    try {
      final repository = getIt<AuthRepository>();
      final result = await repository.getCurrentUser();
      result.fold(
        (failure) => handleError(failure, StackTrace.current, context: 'loadUser'),
        (user) => state = AsyncValue.data(user),
      );
    } catch (error, stack) {
      handleError(error, stack, context: 'loadUser');
    }
  }
}
```

## 性能优化技巧

### 1. 精确监听

```dart
// ❌ 监听整个复杂对象
final user = ref.watch(userProvider);
return Text(user.name); // 用户其他属性变化也会重建

// ✅ 只监听需要的部分
final userName = ref.watch(userProvider.select((user) => user.name));
return Text(userName); // 只有name变化才重建
```

### 2. 条件监听

```dart
class ConditionalWidget extends ConsumerWidget {
  final bool shouldWatch;
  
  const ConditionalWidget({required this.shouldWatch});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 条件监听
    final data = shouldWatch 
        ? ref.watch(dataProvider)
        : null;
    
    return data != null 
        ? DataWidget(data) 
        : const PlaceholderWidget();
  }
}
```

### 3. 缓存和记忆化

```dart
// 使用参数化 Provider 实现缓存
@riverpod
Future<OrderDetailModel> orderDetail(
  Ref ref,
  String serviceExecutionId,
) async {
  // Riverpod 会自动缓存不同 serviceExecutionId 的结果
  final repository = getIt<OrderRepository>();
  final result = await repository.getOrderDetail(serviceExecutionId);
  return result.fold((f) => throw f, (detail) => detail);
}

// 计算密集型操作的记忆化
@riverpod
List<ChartData> processedChartData(Ref ref) {
  final rawData = ref.watch(rawDataProvider);
  
  // 只有 rawData 变化时才重新计算
  return _expensiveDataProcessing(rawData);
}
```

## 测试策略

### 1. Provider 单元测试

```dart
void main() {
  group('CounterNotifier', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始值应该为0', () {
      final counter = container.read(counterProvider);
      expect(counter, 0);
    });
    
    test('increment 应该增加计数', () {
      final notifier = container.read(counterProvider.notifier);
      notifier.increment();
      
      final counter = container.read(counterProvider);
      expect(counter, 1);
    });
  });
}
```

### 2. 异步 Provider 测试

```dart
void main() {
  group('AuthNotifier', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;
    
    setUp(() async {
      mockAuthRepository = MockAuthRepository();
      
      // 注册 Mock 到 GetIt
      await getIt.reset();
      getIt.registerSingleton<AuthRepository>(mockAuthRepository);
      
      container = ProviderContainer();
    });
    
    test('login 成功时应该更新状态', () async {
      // Arrange
      final user = User(id: '1', name: 'Test User');
      when(() => mockAuthRepository.phoneLogin(phone: any(), smsCode: any()))
          .thenAnswer((_) async => Right(user));
      
      // Act
      final notifier = container.read(authProvider.notifier);
      await notifier.login('13800138000', '123456');
      
      // Assert
      final state = container.read(authProvider);
      expect(state.hasValue, true);
    });
  });
}
```

### 3. Widget 测试

```dart
void main() {
  testWidgets('UserProfilePage 应该显示用户信息', (tester) async {
    // Arrange
    final user = User(id: '1', name: 'Test User');
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => user),
        ],
        child: const MaterialApp(
          home: UserProfilePage(),
        ),
      ),
    );
    
    // Assert
    expect(find.text('Test User'), findsOneWidget);
  });
}
```

## 实际项目案例

> 以下示例基于本项目实际代码，展示 Riverpod 在生产环境中的使用方式。

### 认证流程管理

项目使用 `@Riverpod(keepAlive: true)` 管理认证状态：**Provider 统一直接调用 `AuthRepository`，不使用 UseCase 层**。登录在 `phoneLogin` 中内联手机号/验证码校验与 `PhoneLoginRequest` 组装后调用 `_authRepository.phoneLogin`；本地恢复、拉取用户、登出、Token 校验等同样直接调用 `AuthRepository`。

```dart
// lib/features/auth/presentation/providers/models/auth_state.dart
// 单一数据类，使用 abstract class
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    UserEntity? user,
    String? accessToken,
    String? errorMessage,
    @Default(false) bool isLoading,
    AuthStateChangeReason? changeReason,
    DateTime? changeTime,
    String? changeContext,
  }) = _AuthState;
}

// lib/features/auth/presentation/providers/auth_provider.dart
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = getIt<AuthRepository>();

    // 监听网络层认证错误（TokenExpired / AuthenticationFailed）
    _listenToAuthEvents();

    // 初始化时从本地存储恢复认证状态
    unawaited(_initializeAuth());
    return const AuthState(isLoading: true);
  }

  /// 手机号登录（项目使用手机号+验证码，非 email/password）
  Future<void> phoneLogin({
    required String phonenumber,
    required String smsCode,
  }) async {
    state = state.copyWith(errorMessage: null, isLoading: true);

    try {
      final phone = phonenumber.trim();
      final phoneErrMsg = ValidatorsCheck.checkPhoneNumber(phone);
      if (ValidatorsCheck.hasError(phoneErrMsg)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: phoneErrMsg,
          changeReason: AuthStateChangeReason.loginFailed,
          changeTime: DateTime.now(),
        );
        return;
      }

      final code = smsCode.trim();
      final codeErrMsg = ValidatorsCheck.checkSMSCode(code);
      if (ValidatorsCheck.hasError(codeErrMsg)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: codeErrMsg,
          changeReason: AuthStateChangeReason.loginFailed,
          changeTime: DateTime.now(),
        );
        return;
      }

      final request = PhoneLoginRequest(
        clientId: AppConfig.clientId,
        grantType: 'sms',
        phonenumber: phone,
        smsCode: code,
      );
      final result = await _authRepository.phoneLogin(request);

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            changeReason: AuthStateChangeReason.loginFailed,
            changeTime: DateTime.now(),
          );
        },
        (authResponse) {
          state = state.copyWith(
            accessToken: authResponse.accessToken,
            isLoading: false,
            changeReason: AuthStateChangeReason.loginSuccess,
            changeTime: DateTime.now(),
          );
          unawaited(_refreshUserInfo());
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '登录失败，请重试',
        changeReason: AuthStateChangeReason.loginFailed,
        changeTime: DateTime.now(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.logout();
      state = AuthState(
        changeReason: AuthStateChangeReason.logoutCompleted,
        changeTime: DateTime.now(),
      );
    } catch (e) {
      state = AuthState(
        changeReason: AuthStateChangeReason.logoutCompleted,
        changeTime: DateTime.now(),
      );
    }
  }

  // _initializeAuth / _refreshUserInfo 等内部方法中调用 _authRepository
  // （如 getLocalAuthInfo、getCurrentUser、isTokenValid）
}
```

**要点**：
- 类名为 `Auth`（非 `AuthNotifier`），生成的 Provider 为 `authProvider`
- 使用 `getIt<>()` (GetIt) 获取 `AuthRepository`，而非 `ref.read(xxxProvider)` 注入服务
- **Provider 统一直接调用 Repository，不使用 UseCase 层**；参数校验、`PhoneLoginRequest` 组装等业务逻辑内联在 Provider
- `AuthState` 是单一数据类（`class`），不是联合类型（`sealed class`）
- 通过 `AuthStateChangeReason` 枚举追踪状态变化原因
- 使用 `ref.listen()` 监听网络层认证错误流

### 路由守卫（auto_route）

项目使用 `auto_route` 而非 `GoRouter`，路由守卫通过 `AutoRouteGuard` 实现：

```dart
// lib/core/router/guards/auth_guard.dart
class AuthGuard extends AutoRouteGuard {
  final Ref _ref;

  AuthGuard(this._ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final authState = _ref.read(authProvider);

    if (authState.isAuthenticated) {
      resolver.next(true);
    } else {
      resolver.redirect(const LoginRoute());
    }
  }
}

// lib/core/router/app_router.dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter({required this.authGuard, required this.debouncerGuard});

  final AuthGuard authGuard;
  final DebouncerGuard debouncerGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
      guards: [authGuard, debouncerGuard],
    ),
    // ...
  ];
}
```

**要点**：
- 使用 `auto_route` 的 `AutoRouteGuard`，而非 GoRouter 的 `redirect`
- 通过 `_ref.read(authProvider)` 读取认证状态
- 路由守卫在 `AppRouter` 构造函数中注入

## 总结

Riverpod 提供了强大而灵活的状态管理能力：

### 核心优势

- **类型安全**：编译时错误检查
- **性能优化**：自动优化重建
- **可测试性**：优秀的测试支持
- **开发体验**：丰富的开发工具

### 最佳实践要点

1. **使用 @riverpod 注解**：简化代码，提升类型安全
2. **合理设计状态结构**：保持扁平化，避免过度嵌套
3. **精确监听**：使用 select 避免不必要的重建
4. **统一错误处理**：建立完善的错误处理机制
5. **充分测试**：为关键的 Provider 编写单元测试

通过遵循这些指南和最佳实践，你可以构建出高质量、可维护的 Flutter 应用。
