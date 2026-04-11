# Talker 日志系统集成文档

## 概述

本项目已成功集成 Talker 日志系统，包括：

- `talker_flutter`: 核心日志框架
- `talker_dio_logger`: Dio 网络请求日志记录
- `talker_riverpod_logger`: Riverpod 状态管理日志记录

## 架构设计

### 统一日志实例

所有日志记录器（Talker、TalkerDioLogger、TalkerRiverpodObserver）共享同一个 Talker 实例，确保日志的一致性和可追踪性。

```
AppLogger (统一日志接口)
    ↓
Talker (核心实例)
    ↓
┌──────────────┬──────────────────┬─────────────────────┐
│              │                  │                     │
TalkerDioLogger   TalkerRiverpodObserver   其他观察器
(网络日志)          (状态管理日志)          (文件/第三方等)
```

## 核心组件

### 1. AppLogger

位置：`lib/core/logger/app_logger.dart`

**新增属性：**

```dart
static TalkerDioLogger? _dioLogger;
static TalkerRiverpodObserver? _riverpodObserver;
```

**新增 Getter：**

```dart
// 获取 TalkerDioLogger 实例（用于 ApiClient）
static TalkerDioLogger? get dioLogger => _dioLogger;

// 获取 TalkerRiverpodObserver 实例（用于 ProviderScope）
static TalkerRiverpodObserver? get riverpodObserver => _riverpodObserver;
```

**初始化流程：**

```dart
static Future<void> initialize() async {
  // 1. 创建日志上下文
  _context = await LogContext.create();
  
  // 2. 创建 Talker 实例
  _talker = await TalkerConfig.createTalker(...);
  
  // 3. 创建 Dio Logger（共享 Talker 实例）
  _dioLogger = TalkerConfig.createDioLogger(_talker, environment);
  
  // 4. 创建 Riverpod Observer（共享 Talker 实例）
  _riverpodObserver = TalkerConfig.createRiverpodObserver(_talker, environment);
}
```

### 2. TalkerConfig

位置：`lib/core/logger/talker_config.dart`

**新增方法：**

#### createDioLogger

创建 TalkerDioLogger 实例，用于记录 Dio 网络请求。

```dart
static TalkerDioLogger createDioLogger(Talker talker, String environment) {
  final isDebug = kDebugMode || environment == 'development';

  return TalkerDioLogger(
    talker: talker,
    settings: TalkerDioLoggerSettings(
      // 请求日志配置
      printRequestHeaders: isDebug,
      printRequestData: isDebug,

      // 响应日志配置
      printResponseHeaders: isDebug,
      printResponseData: isDebug,

      // 彩色输出
      requestPen: AnsiPen()..blue(),
      responsePen: AnsiPen()..green(),
      errorPen: AnsiPen()..red(),
    ),
  );
}
```

#### createRiverpodObserver

创建 TalkerRiverpodObserver 实例，用于记录 Riverpod 状态变化。

```dart
static TalkerRiverpodObserver createRiverpodObserver(
  Talker talker,
  String environment,
) {
  final isDebug = kDebugMode || environment == 'development';

  return TalkerRiverpodObserver(
    talker: talker,
    settings: TalkerRiverpodLoggerSettings(
      enabled: isDebug,
      printProviderAdded: isDebug,
      printProviderUpdated: false, // 更新日志过多，默认关闭
      printProviderDisposed: isDebug,
      printStateFullData: false, // 不打印完整状态数据，避免日志过长
    ),
  );
}
```

### 3. ApiClient

位置：`lib/core/network/api_client.dart`

**修改内容：**

#### 移除依赖

- 移除 `pretty_dio_logger` 依赖
- 移除 `flutter/foundation.dart` 导入（kDebugMode 不再需要）

#### 新增参数

```dart
class ApiClient {
  ApiClient(BaseOptions options, {TalkerDioLogger? dioLogger}) {
    _dio = Dio();
    _dioLogger = dioLogger;
    _setupDio(options);
  }

  late final Dio _dio;
  TalkerDioLogger? _dioLogger;
```

#### 拦截器修改

```dart
void _setupInterceptors() {
  // 请求拦截器 - 添加认证token
  _dio.interceptors.add(AuthInterceptor());

  // 日志拦截器 - 使用 TalkerDioLogger
  if (_dioLogger != null) {
    _dio.interceptors.add(_dioLogger!);
  }
}
```

### 4. ServiceLocator

位置：`lib/core/di/service_locator.dart`

**修改内容：**

注入 `TalkerDioLogger` 到 `ApiClient`（位于 `lib/core/di/service_locator.dart`）：

```dart
@singleton
ApiClient get apiClient => ApiClient(
  BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConstants.connectionTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
  ),
  dioLogger: AppLogger.dioLogger,
);
```

### 5. main.dart

位置：`lib/main.dart`

**修改内容：**

使用 `TalkerRiverpodObserver` 替换自定义的 `ProviderLogger`：

```dart
void main() async {
  await _initializeApp();

  runApp(
    ProviderScope(
      observers: [
        // 使用 TalkerRiverpodObserver 进行日志记录
        if (AppLogger.riverpodObserver != null) AppLogger.riverpodObserver!,
      ],
      child: const MyApp(),
    ),
  );
}
```

> **注意**：如果您集成了第三方 APM 监控（可选），可以在此处将其 observer 一并传入 `navigatorObservers`。

`TalkerRouteObserver` 在 `MyApp.build()` 中通过 auto_route 的 `navigatorObservers` 集成：

```dart
routerConfig: appRouter.config(
  navigatorObservers: () => [
    // 可选：添加第三方监控 observer
    AppLogger.routeObserver!,
  ],
),
```

### 6. ProviderLogger (已删除)

位置：`lib/core/di/provider_logger.dart`

**操作：** 删除此文件

**原因：** 使用 `TalkerRiverpodObserver` 替代自定义的 `ProviderLogger`，功能更强大且集成更好。

## 日志配置

### 开发环境 (development)

- ✅ 打印所有网络请求和响应详情（请求头、请求体、响应头、响应体）
- ✅ 打印 Provider 添加、销毁事件
- ❌ 不打印 Provider 更新事件（过多）
- ❌ 不打印完整状态数据（避免日志过长）

### 预发布环境 (staging)

- ❌ 不打印请求头、请求体、响应头、响应体
- ❌ Riverpod Observer 禁用（enabled: false）

### 生产环境 (production)

- ❌ 不打印请求/响应详情
- ❌ Riverpod Observer 禁用（enabled: false）
- ✅ 可选：启用第三方监控观察器上报错误

## 使用示例

### 1. 查看网络日志

网络请求日志会自动记录，无需手动调用：

```dart
// 发起请求
final response = await apiClient.get('/api/users');

// 日志会自动记录：
// - 请求 URL
// - 请求方法
// - 请求头（开发环境）
// - 请求体（开发环境）
// - 响应状态码
// - 响应头（开发环境）
// - 响应数据（开发环境）
// - 错误信息（所有环境）
```

### 2. 查看 Riverpod 日志

Provider 状态变化日志会自动记录：

```dart
// 创建 Provider
@riverpod
class UserProvider extends _$UserProvider {
  @override
  Future<User> build() async {
    // 日志：Provider added: UserProvider
    return fetchUser();
  }
}

// 使用 Provider
final user = ref.watch(userProvider);

// Provider 失败时
// 日志：Provider failed: UserProvider
//      Error: xxx
//      StackTrace: xxx
```

### 3. 查看所有日志

在应用中查看 Talker 日志屏幕：

```dart
// 方式1：通过 auto_route 路由跳转（推荐）
context.router.push(const LoggerViewerRoute());

// 方式2：直接使用 TalkerScreen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => TalkerScreen(talker: AppLogger.talker),
  ),
);
```

> 日志查看器入口位于个人中心页面，仅在 `AppConfig.enableTalkerScreen` 为 `true` 时显示。

## 依赖版本

```yaml
dependencies:
  talker_flutter: ^5.0.0
  talker_dio_logger: ^5.0.0
  talker_riverpod_logger: ^5.0.2
```

## 优势

### 1. 统一的日志管理

- 所有日志记录器使用同一个 Talker 实例
- 日志可以在统一的界面中查看和过滤
- 支持导出、分享日志

### 2. 自动化日志记录

- Dio 网络请求自动记录
- Riverpod 状态管理自动记录
- 无需手动添加日志代码

### 3. 环境感知

- 根据环境自动调整日志详细程度
- 开发环境：详细日志
- 生产环境：仅错误日志

### 4. 性能优化

- 使用过滤器减少不必要的日志
- 限制历史日志数量
- 异步写入文件（测试/生产环境）

## 注意事项

### 1. 敏感信息过滤

日志系统已内置敏感信息过滤（通过 `SensitiveFilter`），会自动过滤：

- 密码
- Token
- 身份证号
- 手机号
- 邮箱
- 其他敏感字段

### 2. 性能考虑

- 开发环境：打印详细日志可能影响性能
- 生产环境：仅记录错误，对性能影响最小
- 日志历史：限制最大条目数，避免内存占用过大

### 3. 日志存储

- 测试/生产环境：日志会自动写入文件
- 文件位置：应用文档目录 `/logs/`
- 文件轮转：自动管理日志文件大小

## 后续优化建议

1. **添加日志分析功能**
   - 统计网络请求成功率
   - 统计 Provider 失败率
   - 性能监控

2. **远程日志上报**
   - 集成 Sentry 或其他日志平台
   - 自动上报严重错误

3. **日志检索优化**
   - 添加更多过滤条件
   - 支持关键词搜索
   - 支持时间范围筛选

4. **日志可视化**
   - 网络请求时序图
   - Provider 状态流转图
   - 错误趋势分析

## 相关文档

- [Talker 官方文档](https://github.com/Frezyx/talker)
- [talker_dio_logger 文档](https://pub.dev/packages/talker_dio_logger)
- [talker_riverpod_logger 文档](https://pub.dev/packages/talker_riverpod_logger)

## 更新日期

2026-03-17
