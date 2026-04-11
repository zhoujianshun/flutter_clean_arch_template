# Freezed: sealed vs abstract 使用指南

## 📋 概述

Freezed 3.0+ 要求明确使用 `sealed` 或 `abstract` 关键字来声明类。本文档详细说明这两种关键字的使用场景和最佳实践。

> **重要变更**：从 Freezed 3.0 开始，你必须显式声明类为 `sealed` 或 `abstract`。

## 🎯 核心区别

| 特性 | sealed class | abstract class |
|-----|-------------|----------------|
| **构造函数数量** | 多个（2个或以上） | 单个 |
| **用途** | 联合类型、状态管理 | 数据模型、DTO |
| **模式匹配** | ✅ 支持（when/map/switch） | ❌ 不支持 |
| **穷举检查** | ✅ 编译期强制 | ❌ 无需 |
| **子类限制** | 只能在同一文件内定义 | 无限制 |
| **典型示例** | State、Event、Result | Entity、Model、Config |

## 1️⃣ sealed class - 联合类型

### 🎯 使用场景

#### ✅ 适合使用 sealed class 的情况

1. **状态管理** - 多种互斥的状态
2. **错误处理** - 多种错误类型
3. **事件系统** - 多种事件类型
4. **结果类型** - Success/Failure 模式
5. **需要模式匹配** - 需要穷举所有情况

### 📝 语法格式

```dart
@freezed
sealed class ClassName with _$ClassName {
  const factory ClassName.variant1(...) = _Variant1;
  const factory ClassName.variant2(...) = _Variant2;
  const factory ClassName.variant3(...) = _Variant3;
}
```

### 💡 实际示例

#### 示例 1：状态管理

```dart
@freezed
sealed class AuthState with _$AuthState {
  /// 初始状态
  const factory AuthState.initial() = _Initial;
  
  /// 加载中
  const factory AuthState.loading() = _Loading;
  
  /// 认证成功
  const factory AuthState.authenticated({
    required UserEntity user,
    required String token,
  }) = _Authenticated;
  
  /// 未认证
  const factory AuthState.unauthenticated({
    String? error,
  }) = _Unauthenticated;
}

// 使用 Dart 3 的 switch 表达式（推荐）
Widget buildAuthUI(AuthState state) {
  return switch (state) {
    _Initial() => const Text('初始化中...'),
    _Loading() => const CircularProgressIndicator(),
    _Authenticated(user: final user) => Text('欢迎, ${user.nickname}'),
    _Unauthenticated(error: final error) => Text('错误: ${error ?? "未登录"}'),
  };
}

// 或使用 Freezed 生成的 when 方法
String getStateMessage(AuthState state) {
  return state.when(
    initial: () => '初始化',
    loading: () => '加载中',
    authenticated: (user, token) => '已登录: ${user.nickname}',
    unauthenticated: (error) => '未登录: ${error ?? ""}',
  );
}
```

#### 示例 2：错误处理

```dart
@freezed
sealed class Failure with _$Failure {
  /// 服务器错误
  const factory Failure.server({
    required String message,
    @Default(500) int code,
  }) = ServerFailure;

  /// 网络错误
  const factory Failure.network({
    required String message,
    @Default(-1) int code,
  }) = NetworkFailure;

  /// 验证错误
  const factory Failure.validation({
    required String message,
    @Default(400) int code,
  }) = ValidationFailure;

  /// 认证错误
  const factory Failure.auth({
    required String message,
    @Default(401) int code,
  }) = AuthFailure;
}

// 使用 switch 表达式处理错误
String getErrorMessage(Failure failure) {
  return switch (failure) {
    ServerFailure(message: final msg) => '服务器错误: $msg',
    NetworkFailure(message: final msg) => '网络连接失败: $msg',
    ValidationFailure(message: final msg) => '数据验证失败: $msg',
    AuthFailure(message: final msg) => '认证失败: $msg',
  };
}

// 使用 maybeWhen 处理部分情况
IconData getErrorIcon(Failure failure) {
  return failure.maybeWhen(
    network: (_, __) => Icons.wifi_off,
    auth: (_, __) => Icons.lock,
    orElse: () => Icons.error,
  );
}
```

#### 示例 3：事件系统

```dart
/// 认证事件 - 用于跨模块通信
sealed class AuthEvent {
  const AuthEvent();

  /// 登录成功
  const factory AuthEvent.loginSuccess(AuthResponseEntity authResponse) = 
      LoginSuccessEvent;

  /// 登录失败
  const factory AuthEvent.loginFailed(String message) = 
      LoginFailedEvent;

  /// 退出登录
  const factory AuthEvent.logoutCompleted(
    LogoutReason reason,
    String message,
  ) = LogoutCompletedEvent;

  /// Token过期
  const factory AuthEvent.tokenExpired(String message) = 
      TokenExpiredEvent;
}

// 具体事件类
class LoginSuccessEvent extends AuthEvent {
  const LoginSuccessEvent(this.authResponse);
  final AuthResponseEntity authResponse;
}

class LoginFailedEvent extends AuthEvent {
  const LoginFailedEvent(this.message);
  final String message;
}

// 使用 switch 处理事件
void handleAuthEvent(AuthEvent event) {
  switch (event) {
    case LoginSuccessEvent(authResponse: final response):
      // 处理登录成功
      print('登录成功: ${response.user.nickname}');
      break;
    case LoginFailedEvent(message: final msg):
      // 处理登录失败
      print('登录失败: $msg');
      break;
    case LogoutCompletedEvent():
      // 处理退出登录
      print('已退出登录');
      break;
    case TokenExpiredEvent():
      // 处理 Token 过期
      print('Token 已过期');
      break;
  }
}
```

#### 示例 4：Result 类型

```dart
@freezed
sealed class Result<T, E> with _$Result<T, E> {
  /// 成功
  const factory Result.success(T data) = Success<T, E>;
  
  /// 失败
  const factory Result.failure(E error) = Failure<T, E>;
}

// 使用泛型 Result
Future<Result<User, String>> login(String username, String password) async {
  try {
    final user = await authApi.login(username, password);
    return Result.success(user);
  } catch (e) {
    return Result.failure(e.toString());
  }
}

// 使用 switch 表达式处理结果
Widget buildLoginResult(Result<User, String> result) {
  return switch (result) {
    Success(data: final user) => Text('欢迎, ${user.nickname}'),
    Failure(error: final error) => Text('错误: $error'),
  };
}
```

### 🔍 sealed class 的特点

#### 1. 编译期穷举检查

```dart
// ✅ 正确 - 处理了所有情况
String getMessage(AuthState state) {
  return switch (state) {
    _Initial() => '初始化',
    _Loading() => '加载中',
    _Authenticated() => '已认证',
    _Unauthenticated() => '未认证',
  }; // ✅ 编译通过
}

// ❌ 错误 - 缺少某个分支
String getMessage(AuthState state) {
  return switch (state) {
    _Initial() => '初始化',
    _Loading() => '加载中',
    // 缺少 _Authenticated 和 _Unauthenticated
  }; // ❌ 编译错误：未处理所有情况
}
```

#### 2. 类型安全的解构

```dart
void handleState(AuthState state) {
  if (state is _Authenticated) {
    // 编译器知道这里是 _Authenticated 类型
    final user = state.user;      // ✅ 类型安全访问
    final token = state.token;    // ✅ 类型安全访问
    print('用户: ${user.nickname}, Token: $token');
  }
}
```

#### 3. 无法在文件外扩展

```dart
// ❌ 错误 - sealed class 的子类必须在同一文件内定义
// 这个在另一个文件中会编译失败
class CustomAuthState extends AuthState { } // ❌ 编译错误
```

## 2️⃣ abstract class - 单一数据类

### 🎯 使用场景

#### ✅ 适合使用 abstract class 的情况

1. **数据传输对象（DTO）** - API 请求/响应模型
2. **领域实体（Entity）** - 业务核心对象
3. **配置对象** - 应用配置、设置
4. **单一构造函数** - 只有一种形式的数据
5. **需要 JSON 序列化** - 与后端交互的模型

### 📝 语法格式

```dart
@freezed
abstract class ClassName with _$ClassName {
  const factory ClassName({
    required Type field1,
    Type? field2,
    @Default(value) Type field3,
  }) = _ClassName;
  
  // 如果需要 JSON 序列化
  factory ClassName.fromJson(Map<String, dynamic> json) => 
      _$ClassNameFromJson(json);
}
```

### 💡 实际示例

#### 示例 1：用户实体（Entity）

```dart
@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    @Number2StringConverter() String? id,
    String? userCode,
    String? nickname,
    String? avatarUrl,
    String? mobile,
    Gender? gender,
    String? address,
    @Default([]) List<String> labels,
  }) = _UserEntity;

  const UserEntity._(); // 私有构造函数，用于添加自定义方法

  factory UserEntity.fromJson(Map<String, dynamic> json) => 
      _$UserEntityFromJson(json);

  // 自定义 getter
  String get displayName => nickname ?? mobile ?? '未命名用户';
  
  // 自定义方法
  bool hasLabel(String label) => labels.contains(label);
}

// 使用示例
final user = UserEntity(
  id: '123',
  nickname: '张三',
  mobile: '13800138000',
  gender: Gender.male,
  labels: ['VIP', '活跃用户'],
);

// 使用 copyWith 创建修改后的副本
final updatedUser = user.copyWith(
  nickname: '李四',
  labels: [...user.labels, '新用户'],
);

// 使用自定义方法
if (user.hasLabel('VIP')) {
  print('VIP 用户: ${user.displayName}');
}
```

#### 示例 2：API 请求模型

```dart
@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String mobile,
    required String code,
    required String type,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => 
      _$LoginRequestFromJson(json);
}

// 使用示例
final request = LoginRequest(
  mobile: '13800138000',
  code: '123456',
  type: 'sms',
);

// 转换为 JSON
final json = request.toJson();
// { "mobile": "13800138000", "code": "123456", "type": "sms" }
```

#### 示例 3：API 响应模型

```dart
@freezed
abstract class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required String msg,
    required int code,
    T? data,
  }) = _ApiResponse<T>;

  const ApiResponse._(); // 支持自定义方法

  // 自定义 getter
  bool get isSuccess => code == 200;
  bool get isFailure => !isSuccess;
  bool get hasData => data != null;
  
  // 工厂方法
  factory ApiResponse.success({
    required T data,
    String message = '操作成功',
  }) {
    return ApiResponse<T>(
      msg: message,
      code: 200,
      data: data,
    );
  }

  factory ApiResponse.failure({
    required String message,
    int code = 400,
  }) {
    return ApiResponse<T>(
      msg: message,
      code: code,
      data: null,
    );
  }
}

// 使用示例
final response = ApiResponse<UserEntity>.success(
  data: userEntity,
  message: '获取用户信息成功',
);

if (response.isSuccess && response.hasData) {
  print('用户: ${response.data!.displayName}');
}
```

#### 示例 4：配置对象

```dart
@freezed
abstract class EditorConfig with _$EditorConfig {
  const factory EditorConfig({
    @Default(true) bool enableCrop,
    @Default(true) bool enableCompress,
    @Default(true) bool enableRotate,
    @Default(0.8) double compressQuality,
    @Default(1024) int maxWidth,
    @Default(1024) int maxHeight,
    CropAspectRatio? aspectRatio,
  }) = _EditorConfig;

  const EditorConfig._();

  factory EditorConfig.fromJson(Map<String, dynamic> json) => 
      _$EditorConfigFromJson(json);

  // 预设配置
  factory EditorConfig.standard() {
    return const EditorConfig(
      compressQuality: 0.8,
      maxWidth: 1024,
      maxHeight: 1024,
    );
  }

  factory EditorConfig.highQuality() {
    return const EditorConfig(
      compressQuality: 0.95,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }

  // 验证方法
  bool get isValid => 
      compressQuality >= 0 && 
      compressQuality <= 1 && 
      maxWidth > 0 && 
      maxHeight > 0;
}

// 使用示例
final config = EditorConfig.standard();
final customConfig = config.copyWith(
  maxWidth: 2048,
  aspectRatio: CropAspectRatio.square(),
);
```

#### 示例 5：分页数据模型

```dart
@Freezed(genericArgumentFactories: true)
abstract class PaginatedData<T> with _$PaginatedData<T> {
  const factory PaginatedData({
    required List<T> rows,
    required int total,
    @Default(false) bool hasNext,
    @Default(false) bool hasPrevious,
    int? currentPage,
    int? pageSize,
  }) = _PaginatedData<T>;

  const PaginatedData._();

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedDataFromJson(json, fromJsonT);

  // 自定义 getter
  bool get hasData => rows.isNotEmpty;
  bool get isEmpty => rows.isEmpty;
  bool get isLastPage => !hasNext;
  bool get isFirstPage => !hasPrevious;
  int get currentPageSize => rows.length;

  // 计算总页数
  int totalPages([int defaultPageSize = 10]) {
    final size = pageSize ?? defaultPageSize;
    return (total / size).ceil();
  }
}

// 使用示例
final paginatedUsers = PaginatedData<UserEntity>(
  rows: [user1, user2, user3],
  total: 100,
  hasNext: true,
  currentPage: 1,
  pageSize: 10,
);

print('当前页: ${paginatedUsers.currentPage}');
print('总页数: ${paginatedUsers.totalPages()}');
print('是否最后一页: ${paginatedUsers.isLastPage}');
```

### 🔍 abstract class 的特点

#### 1. 自动生成样板代码

```dart
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
}

// Freezed 自动生成：
// - copyWith 方法
// - == 运算符
// - hashCode
// - toString
// - toJson (如果有 fromJson)

final user1 = User(id: '1', name: '张三');
final user2 = user1.copyWith(name: '李四');

print(user1 == user2);        // false
print(user1.toString());      // User(id: 1, name: 张三)
print(user1.hashCode);        // 自动生成的 hash
```

#### 2. 支持默认值和可选参数

```dart
@freezed
abstract class Config with _$Config {
  const factory Config({
    required String appName,
    @Default('') String apiUrl,           // 默认值
    @Default(true) bool debugMode,        // 默认布尔值
    @Default([]) List<String> features,   // 默认列表
    String? description,                  // 可选字段
  }) = _Config;
}

// 使用示例
final config1 = Config(appName: 'MyApp');
// apiUrl='', debugMode=true, features=[], description=null

final config2 = Config(
  appName: 'MyApp',
  apiUrl: 'https://api.example.com',
  debugMode: false,
  features: ['feature1', 'feature2'],
);
```

#### 3. 添加自定义方法

```dart
@freezed
abstract class Rectangle with _$Rectangle {
  const factory Rectangle({
    required double width,
    required double height,
  }) = _Rectangle;

  const Rectangle._(); // ⚠️ 必须添加私有构造函数

  // 自定义 getter
  double get area => width * height;
  double get perimeter => 2 * (width + height);
  
  // 自定义方法
  bool isSquare() => width == height;
  
  Rectangle scale(double factor) {
    return copyWith(
      width: width * factor,
      height: height * factor,
    );
  }
}

// 使用示例
final rect = Rectangle(width: 10, height: 20);
print('面积: ${rect.area}');           // 200
print('周长: ${rect.perimeter}');      // 60
print('是否正方形: ${rect.isSquare()}'); // false

final scaled = rect.scale(2);
print('缩放后: ${scaled.width} x ${scaled.height}'); // 20 x 40
```

## 📊 对比总结

### 何时使用 sealed class

```dart
// ✅ 多种状态 - 使用 sealed
@freezed
sealed class LoadingState<T> with _$LoadingState<T> {
  const factory LoadingState.initial() = Initial<T>;
  const factory LoadingState.loading() = Loading<T>;
  const factory LoadingState.success(T data) = Success<T>;
  const factory LoadingState.error(String message) = Error<T>;
}

// ✅ 多种错误 - 使用 sealed
@freezed
sealed class ApiError with _$ApiError {
  const factory ApiError.network(String message) = NetworkError;
  const factory ApiError.server(int code, String message) = ServerError;
  const factory ApiError.timeout() = TimeoutError;
}

// ✅ 多种事件 - 使用 sealed
sealed class OrderEvent {
  const factory OrderEvent.created(Order order) = OrderCreated;
  const factory OrderEvent.updated(Order order) = OrderUpdated;
  const factory OrderEvent.cancelled(String reason) = OrderCancelled;
}
```

### 何时使用 abstract class

```dart
// ✅ 数据模型 - 使用 abstract
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
  }) = _User;
}

// ✅ DTO - 使用 abstract
@freezed
abstract class CreateOrderRequest with _$CreateOrderRequest {
  const factory CreateOrderRequest({
    required String serviceId,
    required String customerId,
    required DateTime scheduledTime,
  }) = _CreateOrderRequest;
}

// ✅ 配置 - 使用 abstract
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String apiBaseUrl,
    @Default(30) int timeout,
    @Default(true) bool enableLogging,
  }) = _AppConfig;
}
```

## 🚨 常见错误

### ❌ 错误 1：单一构造函数使用 sealed

```dart
// ❌ 错误 - 只有一个构造函数，应该用 abstract
@freezed
sealed class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
}

// ✅ 正确 - 单一构造函数用 abstract
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
}
```

### ❌ 错误 2：多个构造函数使用 abstract

```dart
// ❌ 错误 - 多个构造函数，应该用 sealed
@freezed
abstract class Result with _$Result {
  const factory Result.success(String data) = Success;
  const factory Result.failure(String error) = Failure;
}

// ✅ 正确 - 多个构造函数用 sealed
@freezed
sealed class Result with _$Result {
  const factory Result.success(String data) = Success;
  const factory Result.failure(String error) = Failure;
}
```

### ❌ 错误 3：忘记私有构造函数

```dart
// ❌ 错误 - 添加自定义方法但没有私有构造函数
@freezed
abstract class User with _$User {
  const factory User({
    required String firstName,
    required String lastName,
  }) = _User;
  
  // ❌ 编译错误 - 缺少私有构造函数
  String get fullName => '$firstName $lastName';
}

// ✅ 正确 - 添加私有构造函数
@freezed
abstract class User with _$User {
  const factory User({
    required String firstName,
    required String lastName,
  }) = _User;
  
  const User._(); // ✅ 添加私有构造函数
  
  String get fullName => '$firstName $lastName';
}
```

### ❌ 错误 4：不一致的命名

```dart
// ❌ 错误 - 构造函数命名不一致
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = Initial;        // ❌ 缺少下划线
  const factory AuthState.loading() = _Loading;       // ✅ 正确
  const factory AuthState.authenticated() = Auth;     // ❌ 名称不匹配
}

// ✅ 正确 - 统一命名规范
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated() = _Authenticated;
}
```

## 🎯 最佳实践

### 1. 选择合适的关键字

```dart
// 问自己：这个类有多个互斥的变体吗？

// 是 → 使用 sealed class
@freezed
sealed class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod.cash() = Cash;
  const factory PaymentMethod.card(String cardNumber) = Card;
  const factory PaymentMethod.alipay(String account) = Alipay;
}

// 否 → 使用 abstract class
@freezed
abstract class PaymentInfo with _$PaymentInfo {
  const factory PaymentInfo({
    required String orderId,
    required double amount,
    required DateTime paidAt,
  }) = _PaymentInfo;
}
```

### 2. 合理使用 @Default

```dart
@freezed
abstract class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default('zh_CN') String language,           // 默认语言
    @Default(true) bool enableNotifications,     // 默认开启通知
    @Default(ThemeMode.system) ThemeMode theme,  // 默认系统主题
    @Default([]) List<String> favoriteIds,       // 默认空列表
  }) = _UserPreferences;
}
```

### 3. 文档注释

```dart
/// 用户实体
///
/// 表示系统中的用户信息，包含基本资料和状态
@freezed
abstract class UserEntity with _$UserEntity {
  /// 创建用户实体
  ///
  /// [id] 用户唯一标识
  /// [nickname] 用户昵称
  /// [mobile] 手机号码
  /// [status] 用户状态，默认为激活
  const factory UserEntity({
    required String id,
    String? nickname,
    String? mobile,
    @Default('active') String status,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) => 
      _$UserEntityFromJson(json);
}
```

### 4. 使用泛型

```dart
// 通用的 Result 类型
@freezed
sealed class Result<T, E> with _$Result<T, E> {
  const factory Result.success(T data) = Success<T, E>;
  const factory Result.failure(E error) = Failure<T, E>;
}

// 通用的异步状态
@freezed
sealed class AsyncState<T> with _$AsyncState<T> {
  const factory AsyncState.initial() = Initial<T>;
  const factory AsyncState.loading() = Loading<T>;
  const factory AsyncState.data(T value) = Data<T>;
  const factory AsyncState.error(Object error, StackTrace stackTrace) = Error<T>;
}
```

## 🔗 项目中的实际应用

### 当前项目中的 sealed class 示例

1. **错误处理** (`lib/core/errors/failures.dart`)

   ```dart
   @freezed
   sealed class Failure with _$Failure {
     // ✅ 已修改为 sealed，支持 switch 穷举检查
   }
   ```

2. **事件系统** (`lib/features/auth/domain/entities/auth_event.dart`)

   ```dart
   sealed class AuthEvent {
     // ✅ 正确使用 sealed
   }
   ```

3. **图片数据** (`lib/shared/widgets/image_preview/my_image_page/models/image_data.dart`)

   ```dart
   sealed class ImageData {
     // ✅ 正确使用 sealed（非 Freezed）
   }
   ```

### 当前项目中的 abstract class 示例

1. **用户实体** (`lib/features/auth/domain/entities/user_entity.dart`)

   ```dart
   @freezed
   abstract class UserEntity with _$UserEntity {
     // ✅ 正确使用 abstract
   }
   ```

2. **API 响应** (`lib/shared/models/api/api_response.dart`)

   ```dart
   @freezed
   abstract class ApiResponse<T> with _$ApiResponse<T> {
     // ✅ 正确使用 abstract
   }
   ```

3. **配置对象** (`lib/shared/widgets/image_editor/models/editor_config.dart`)

   ```dart
   @freezed
   abstract class EditorConfig with _$EditorConfig {
     // ✅ 正确使用 abstract
   }
   ```

## 📚 参考资源

- [Freezed 官方文档](https://pub.dev/packages/freezed)
- [Freezed GitHub](https://github.com/rrousselGit/freezed)
- [Dart 3 模式匹配](https://dart.dev/language/patterns)
- [项目 Freezed 迁移指南](./FREEZED_MIGRATION_GUIDE.md)

## ✅ 检查清单

使用这个检查清单来决定使用哪个关键字：

- [ ] 类是否有多个构造函数？
  - **是** → 使用 `sealed class`
  - **否** → 使用 `abstract class`

- [ ] 是否需要模式匹配和穷举检查？
  - **是** → 使用 `sealed class`
  - **否** → 使用 `abstract class`

- [ ] 是否表示互斥的状态/事件/结果？
  - **是** → 使用 `sealed class`
  - **否** → 使用 `abstract class`

- [ ] 是否是简单的数据容器（DTO/Entity）？
  - **是** → 使用 `abstract class`
  - **否** → 考虑使用 `sealed class`

---

**总结**：简单记住 - **多个变体用 sealed，单一数据用 abstract**。
