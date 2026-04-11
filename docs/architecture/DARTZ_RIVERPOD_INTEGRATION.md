# Dartz + Riverpod 集成指南

## 📖 概述

本指南展示如何在使用 Riverpod 状态管理的 Flutter 应用中有效集成 dartz 进行错误处理。我们将探讨各种集成模式、最佳实践和实际应用场景。

> **⚠️ Freezed 3.0+ 重要说明**：本文档中的 Freezed 代码示例已更新以符合 Freezed 3.0+ 规范：
> - **联合类型**（多个构造函数）使用 `sealed class`
> - **单一数据类**（单个构造函数）使用 `abstract class`
> - 详细说明请查看 [FREEZED_SEALED_VS_ABSTRACT.md](./FREEZED_SEALED_VS_ABSTRACT.md)

## 🎯 核心集成模式

> **架构约定**：**Presentation 层 Provider 统一直接调用 Repository，不使用 UseCase 层**。以下示例中的 `getIt<AuthRepository>()`、`getIt<ExampleRepository>()` 即当前推荐写法；登录等场景的参数校验与请求组装在 Provider 内联完成。

### 1. Provider 中的 Either 处理

#### 基础 FutureProvider 集成

```dart
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

/// 获取当前用户信息的 Provider（直接调用 Repository）
@riverpod
Future<Either<Failure, CurrentUserInfoModel>> currentUserInfo(Ref ref) async {
 final repository = getIt<AuthRepository>();
 return repository.getCurrentUser();
}

/// 在 UI 中使用
class UserProfilePage extends ConsumerWidget {
 const UserProfilePage({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final userAsync = ref.watch(currentUserInfoProvider);

 return Scaffold(
 body: userAsync.when(
 data: (either) => either.fold(
 (failure) => ErrorWidget(failure.message),
 (user) => UserProfileWidget(user: user),
 ),
 loading: () => const CircularProgressIndicator(),
 error: (error, stack) => ErrorWidget(error.toString()),
 ),
 );
 }
}
```

#### 使用 AsyncValue 包装 Either

```dart
/// 将 Either 转换为 AsyncValue 的扩展
extension EitherToAsync<L, R> on Either<L, R> {
 AsyncValue<R> toAsyncValue() {
 return fold(
 (failure) => AsyncValue.error(failure, StackTrace.current),
 (value) => AsyncValue.data(value),
 );
 }
}

/// 直接返回 AsyncValue 的 Provider
@riverpod
Future<CurrentUserInfoModel> currentUserInfoDirect(Ref ref) async {
 final repository = getIt<AuthRepository>();
 final result = await repository.getCurrentUser();

 return result.fold(
 (failure) => throw failure,
 (user) => user,
 );
}
```

### 2. StateNotifier 中的 Either 处理

```dart
/// 认证状态 - 项目实际使用单一数据类（非联合类型）
/// 通过 AuthStateChangeReason 枚举追踪状态变化原因
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

/// 认证状态管理
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
 late final AuthRepository _authRepository = getIt<AuthRepository>();

 @override
 AuthState build() {
 _initializeAuth();
 return const AuthState(isLoading: true);
 }

 /// 手机号登录（参数校验与 PhoneLoginRequest 组装在 Provider 内联，再调 Repository）
 Future<void> phoneLogin({
 required String phonenumber,
 required String smsCode,
 }) async {
 state = state.copyWith(errorMessage: null, isLoading: true);

 final phone = phonenumber.trim();
 final phoneErrMsg = ValidatorsCheck.checkPhoneNumber(phone);
 if (ValidatorsCheck.hasError(phoneErrMsg)) {
 state = state.copyWith(
 isLoading: false,
 errorMessage: phoneErrMsg,
 changeReason: AuthStateChangeReason.loginFailed,
 changeTime: DateTime.now(),
 changeContext: phoneErrMsg ?? '',
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
 changeContext: codeErrMsg ?? '',
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
 },
 );
 }

 /// 登出（直接调用 Repository）
 Future<void> logout() async {
 state = state.copyWith(isLoading: true);
 await _authRepository.logout();
 state = AuthState(
 changeReason: AuthStateChangeReason.logoutCompleted,
 changeTime: DateTime.now(),
 );
 }

 // ... _initializeAuth() 等内部方法
}
```

### 3. 复杂状态管理

```dart
/// 用户列表状态 - 单一数据容器，使用 abstract class（示例与订单列表行模型一致）
@freezed
abstract class UserListState with _$UserListState {
 const factory UserListState({
 @Default([]) List<ExampleItemModel> users,
 @Default(false) bool isLoading,
 @Default(false) bool hasMore,
 String? errorMessage,
 @Default(1) int currentPage,
 }) = _UserListState;
}

/// 用户列表管理
@riverpod
class UserListNotifier extends _$UserListNotifier {
 @override
 UserListState build() {
 loadUsers();
 return const UserListState();
 }

 /// 加载用户列表
 Future<void> loadUsers({bool refresh = false}) async {
 if (refresh) {
 state = state.copyWith(
 users: [],
 currentPage: 1,
 hasMore: true,
 errorMessage: null,
 );
 }

 if (state.isLoading || !state.hasMore) return;

 state = state.copyWith(isLoading: true, errorMessage: null);

 final repository = getIt<ExampleRepository>();
 final result = await repository.getExampleList(
 ExampleListRequest(
 pageNum: state.currentPage,
 pageSize: 20,
 ),
 );

 result.fold(
 (failure) {
 state = state.copyWith(
 isLoading: false,
 errorMessage: failure.message,
 );
 },
 (paginated) {
 final newRows = paginated.rows;
 state = state.copyWith(
 users: [...state.users, ...newRows],
 isLoading: false,
 hasMore: paginated.hasNext,
 currentPage: state.currentPage + 1,
 );
 },
 );
 }

 /// 删除项目（示例：本地列表更新；实际可先调 Repository 拒单/取消等）
 Future<void> deleteItem(String exampleItemId) async {
 state = state.copyWith(
 users: state.users
 .where((item) => item.exampleItemId != exampleItemId)
 .toList(),
 );
 AppLogger.info('项目已从列表移除');
 }

 /// 更新项目（示例：本地合并列表；实际以仓储接口为准）
 Future<void> updateItem(ExampleItemModel updatedItem) async {
 final repository = getIt<ExampleRepository>();
 // ...
 }
}
```

## 🔄 异步操作链

### 1. 连续异步操作

```dart
/// 订单详情 Provider（组合多个数据；评论接口需业务 userId，与 `ExampleCommentListRequest` 一致）
@riverpod
Future<Either<Failure, OrderDetail>> orderDetail(
 Ref ref,
 String exampleItemId,
 String commentListUserId,
) async {
 final orderRepository = getIt<ExampleRepository>();

 // 获取订单基本信息
 final orderResult =
 await orderRepository.getExampleDetail(exampleItemId);
 if (orderResult.isLeft()) {
 return orderResult.fold(
 (failure) => Left(failure),
 (_) => throw StateError('不可能的情况'),
 );
 }

 final order = orderResult.fold(
 (_) => throw StateError('不可能的情况'),
 (order) => order,
 );

 // 获取订单评论（直接调 Repository）
 final commentsResult = await orderRepository.getComments(
 ExampleCommentListRequest(
 userId: commentListUserId,
 exampleItemId: order.exampleItemId,
 ),
 );
 if (commentsResult.isLeft()) {
 return commentsResult.fold(
 (failure) => Left(failure),
 (_) => throw StateError('不可能的情况'),
 );
 }

 final comments = commentsResult.fold(
 (_) => throw StateError('不可能的情况'),
 (paginated) => paginated.rows,
 );

 // 组合结果
 final detail = OrderDetail(order: order, comments: comments);
 return Right(detail);
}

/// 使用扩展方法简化
@riverpod
Future<Either<Failure, OrderDetail>> orderDetailSimplified(
 Ref ref,
 String exampleItemId,
 String commentListUserId,
) async {
 final orderRepository = getIt<ExampleRepository>();

 return (await orderRepository.getExampleDetail(exampleItemId))
 .flatMapAsync((order) async {
 final commentsResult = await orderRepository.getComments(
 ExampleCommentListRequest(
 userId: commentListUserId,
 exampleItemId: order.exampleItemId,
 ),
 );
 return commentsResult.map(
 (paginated) => OrderDetail(
 order: order,
 comments: paginated.rows,
 ),
 );
 });
}
```

### 2. 并行异步操作

```dart
/// 用户仪表板数据
@riverpod
Future<Either<Failure, DashboardData>> dashboardData(
 Ref ref,
 String userId,
) async {
 final authRepository = getIt<AuthRepository>();
 final orderRepository = getIt<ExampleRepository>();
 final messageRepository = getIt<NotificationRepository>();

 // 并行获取多个数据
 final results = await Future.wait([
 authRepository.getCurrentUser(),
 orderRepository.getRecentOrders(userId),
 messageRepository.getUnreadCount(),
 ]);

 // 检查是否有任何失败
 for (final result in results) {
 if (result.isLeft()) {
 return result.fold(
 (failure) => Left(failure),
 (_) => throw StateError('不可能的情况'),
 );
 }
 }

 // 提取所有成功的结果
 final user = results[0].fold(
 (_) => throw StateError('不可能的情况'),
 (user) => user as User,
 );

 final orders = results[1].fold(
 (_) => throw StateError('不可能的情况'),
 (orders) => orders as List<Order>,
 );

 final notifications = results[2].fold(
 (_) => throw StateError('不可能的情况'),
 (notifications) => notifications as List<Notification>,
 );

 return Right(DashboardData(
 user: user,
 recentOrders: orders,
 unreadNotifications: notifications,
 ));
}
```

## 🎨 UI 集成模式

### 1. 错误处理 Widget

```dart
/// 通用错误处理 Widget
class EitherBuilder<T> extends StatelessWidget {
 final Either<Failure, T> either;
 final Widget Function(T data) onSuccess;
 final Widget Function(Failure failure)? onError;
 final Widget? loadingWidget;

 const EitherBuilder({
 required this.either,
 required this.onSuccess,
 this.onError,
 this.loadingWidget,
 super.key,
 });

 @override
 Widget build(BuildContext context) {
 return either.fold(
 (failure) => onError?.call(failure) ?? DefaultErrorWidget(failure),
 (data) => onSuccess(data),
 );
 }
}

/// 默认错误 Widget
class DefaultErrorWidget extends StatelessWidget {
 final Failure failure;

 const DefaultErrorWidget(this.failure, {super.key});

 @override
 Widget build(BuildContext context) {
 return Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 _getErrorIcon(failure),
 size: 64,
 color: Theme.of(context).colorScheme.error,
 ),
 const SizedBox(height: 16),
 Text(
 failure.message,
 style: Theme.of(context).textTheme.bodyLarge,
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 16),
 ElevatedButton(
 onPressed: () {
 // 重试逻辑
 },
 child: const Text('重试'),
 ),
 ],
 ),
 );
 }

 IconData _getErrorIcon(Failure failure) {
 return switch (failure.runtimeType) {
 NetworkFailure => Icons.wifi_off,
 ServerFailure => Icons.server_error,
 AuthFailure => Icons.lock,
 ValidationFailure => Icons.warning,
 _ => Icons.error,
 };
 }
}
```

### 2. 表单处理

```dart
/// 登录表单状态 - 单一数据容器，使用 abstract class
@freezed
abstract class LoginFormState with _$LoginFormState {
 const factory LoginFormState({
 @Default('') String email,
 @Default('') String password,
 @Default(false) bool isLoading,
 String? errorMessage,
 @Default({}) Map<String, String> fieldErrors,
 }) = _LoginFormState;
}

/// 登录表单管理
@riverpod
class LoginFormNotifier extends _$LoginFormNotifier {
 @override
 LoginFormState build() {
 return const LoginFormState();
 }

 void updateEmail(String email) {
 state = state.copyWith(
 email: email,
 fieldErrors: {...state.fieldErrors}..remove('email'),
 );
 }

 void updatePassword(String password) {
 state = state.copyWith(
 password: password,
 fieldErrors: {...state.fieldErrors}..remove('password'),
 );
 }

 Future<void> submit() async {
 // 客户端验证
 final fieldErrors = <String, String>{};

 if (state.email.isEmpty) {
 fieldErrors['email'] = '请输入邮箱';
 } else if (!_isValidEmail(state.email)) {
 fieldErrors['email'] = '邮箱格式不正确';
 }

 if (state.password.isEmpty) {
 fieldErrors['password'] = '请输入密码';
 } else if (state.password.length < 6) {
 fieldErrors['password'] = '密码至少6位';
 }

 if (fieldErrors.isNotEmpty) {
 state = state.copyWith(fieldErrors: fieldErrors);
 return;
 }

 // 提交登录
 state = state.copyWith(isLoading: true, errorMessage: null);

 final authNotifier = ref.read(authProvider.notifier);
 await authNotifier.phoneLogin(
 phonenumber: state.email, // 项目实际使用手机号
 smsCode: state.password, // 项目实际使用验证码
 );

 // 检查登录结果
 final authState = ref.read(authProvider);
 if (authState.isAuthenticated) {
 state = state.copyWith(isLoading: false);
 } else {
 state = state.copyWith(
 isLoading: false,
 errorMessage: authState.errorMessage,
 );
 }
 }

 bool _isValidEmail(String email) {
 return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
 }
}

/// 登录页面
class LoginPage extends ConsumerWidget {
 const LoginPage({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final formState = ref.watch(loginFormNotifierProvider);
 final formNotifier = ref.read(loginFormNotifierProvider.notifier);

 return Scaffold(
 appBar: AppBar(title: const Text('登录')),
 body: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 children: [
 // 错误消息
 if (formState.errorMessage != null)
 Container(
 width: double.infinity,
 padding: const EdgeInsets.all(12),
 margin: const EdgeInsets.only(bottom: 16),
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.errorContainer,
 borderRadius: BorderRadius.circular(8),
 ),
 child: Text(
 formState.errorMessage!,
 style: TextStyle(
 color: Theme.of(context).colorScheme.onErrorContainer,
 ),
 ),
 ),

 // 邮箱输入框
 TextFormField(
 onChanged: formNotifier.updateEmail,
 decoration: InputDecoration(
 labelText: '邮箱',
 errorText: formState.fieldErrors['email'],
 ),
 keyboardType: TextInputType.emailAddress,
 ),
 const SizedBox(height: 16),

 // 密码输入框
 TextFormField(
 onChanged: formNotifier.updatePassword,
 decoration: InputDecoration(
 labelText: '密码',
 errorText: formState.fieldErrors['password'],
 ),
 obscureText: true,
 ),
 const SizedBox(height: 24),

 // 登录按钮
 SizedBox(
 width: double.infinity,
 child: ElevatedButton(
 onPressed: formState.isLoading ? null : formNotifier.submit,
 child: formState.isLoading
 ? const CircularProgressIndicator()
 : const Text('登录'),
 ),
 ),
 ],
 ),
 ),
 );
 }
}
```

## 🔧 实用扩展

### 1. Either 扩展方法

```dart
/// Future Either 扩展
extension FutureEitherExtensions<L, R> on Future<Either<L, R>> {
 /// 转换为 AsyncValue
 Future<AsyncValue<R>> toAsyncValue() async {
 try {
 final result = await this;
 return result.fold(
 (failure) => AsyncValue.error(failure, StackTrace.current),
 (value) => AsyncValue.data(value),
 );
 } catch (error, stackTrace) {
 return AsyncValue.error(error, stackTrace);
 }
 }

 /// 异步 flatMap
 Future<Either<L, T>> flatMapAsync<T>(
 Future<Either<L, T>> Function(R) mapper,
 ) async {
 final result = await this;
 return result.fold(
 (failure) => Left(failure),
 (value) => mapper(value),
 );
 }
}
```

### 2. Riverpod 特定扩展

```dart
/// Ref 扩展，用于处理 Either
extension RefEitherExtensions on Ref {
 /// 监听 Either Provider 并处理错误
 void listenEither<T>(
 ProviderListenable<AsyncValue<Either<Failure, T>>> provider,
 void Function(T data) onData, {
 void Function(Failure failure)? onError,
 }) {
 listen(provider, (previous, next) {
 next.when(
 data: (either) => either.fold(
 (failure) => onError?.call(failure),
 (data) => onData(data),
 ),
 loading: () {},
 error: (error, stack) {},
 );
 });
 }
}
```

## 📱 完整示例：用户管理应用

```dart
/// 主应用（项目使用 auto_route，而非 GoRouter）
class MyApp extends ConsumerWidget {
 const MyApp({super.key, required this.appRouter});

 final AppRouter appRouter;

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 return MaterialApp.router(
 title: 'Your App',
 routerConfig: appRouter.config(),
 );
 }
}

/// 用户列表页面
class UserListPage extends ConsumerWidget {
 const UserListPage({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final userListState = ref.watch(userListNotifierProvider);
 final userListNotifier = ref.read(userListNotifierProvider.notifier);

 return Scaffold(
 appBar: AppBar(
 title: const Text('用户列表'),
 actions: [
 IconButton(
 icon: const Icon(Icons.refresh),
 onPressed: () => userListNotifier.loadUsers(refresh: true),
 ),
 ],
 ),
 body: RefreshIndicator(
 onRefresh: () => userListNotifier.loadUsers(refresh: true),
 child: Column(
 children: [
 // 错误消息
 if (userListState.errorMessage != null)
 Container(
 width: double.infinity,
 padding: const EdgeInsets.all(16),
 color: Theme.of(context).colorScheme.errorContainer,
 child: Text(
 userListState.errorMessage!,
 style: TextStyle(
 color: Theme.of(context).colorScheme.onErrorContainer,
 ),
 ),
 ),

 // 用户列表
 Expanded(
 child: ListView.builder(
 itemCount: userListState.users.length +
 (userListState.hasMore ? 1 : 0),
 itemBuilder: (context, index) {
 if (index == userListState.users.length) {
 // 加载更多指示器
 if (userListState.isLoading) {
 return const Center(
 child: Padding(
 padding: EdgeInsets.all(16),
 child: CircularProgressIndicator(),
 ),
 );
 } else {
 return TextButton(
 onPressed: () => userListNotifier.loadUsers(),
 child: const Text('加载更多'),
 );
 }
 }

 final user = userListState.users[index];
 return UserListItem(
 user: user,
 onDelete: () => userListNotifier.deleteUser(user.id),
 );
 },
 ),
 ),
 ],
 ),
 ),
 floatingActionButton: FloatingActionButton(
 onPressed: () {
 // 导航到创建用户页面
 },
 child: const Icon(Icons.add),
 ),
 );
 }
}
```

## 📚 总结

通过将 dartz 与 Riverpod 结合使用，我们可以：

1. **类型安全的错误处理** - 在编译时就能发现错误处理问题
2. **一致的状态管理** - 统一的错误处理模式
3. **优雅的异步操作** - 链式操作和组合
4. **可测试的代码** - 清晰的依赖注入和状态管理
5. **更好的用户体验** - 智能的错误恢复和状态管理
6. **与当前架构对齐** - Provider 通过 `getIt<XxxRepository>()` 调用仓储方法取得 `Either`；**不使用 UseCase 层**，校验与请求组装在 Provider 内联。

这种组合为 Flutter 应用提供了强大而灵活的架构基础，既保证了代码质量，又提升了开发效率。
