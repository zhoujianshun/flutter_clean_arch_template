# 性能监控使用指南

## 概述

`PerformanceMonitor` 是一个轻量级的性能监控工具，集成在 `AppLogger` 中，用于监控和记录应用中各种操作的执行时间。

## 核心特性

- ✅ **简单易用** - 多种使用方式，适应不同场景
- ✅ **自动记录** - 自动记录性能数据和统计信息
- ✅ **智能提示** - 自动识别慢操作（> 1秒）
- ✅ **统计分析** - 提供详细的性能统计报告
- ✅ **检查点支持** - 支持在复杂操作中设置检查点
- ✅ **零侵入** - 不影响原有代码逻辑

## 三种使用方式

### 方式 1: 使用 `measure` 监控同步操作

```dart
// 监控同步操作
final result = AppLogger.measure(
  'calculateData',
  () {
    // 执行同步操作
    return complexCalculation();
  },
);

// 日志输出：⚡ [calculateData] 150ms
```

**适用场景：**

- 同步计算
- 数据处理
- 本地存储操作

### 方式 2: 使用 `measureAsync` 监控异步操作

```dart
// 监控异步操作
final user = await AppLogger.measureAsync(
  'fetchUserData',
  () async {
    final response = await api.getUser(userId);
    return User.fromJson(response);
  },
);

// 日志输出：⚡ [fetchUserData] 320ms
```

**适用场景：**

- 网络请求
- 数据库查询
- 异步文件操作

### 方式 3: 使用 `PerformanceTimer` 手动计时

```dart
// 开始计时
final timer = AppLogger.startTimer('processData');

// 执行操作
await step1();
timer.checkpoint('step1完成'); // 输出检查点

await step2();
timer.checkpoint('step2完成'); // 输出检查点

await step3();

// 停止计时
timer.stop();

// 日志输出：
// ⏱️ 开始计时: processData
// ⏱️ [processData] 检查点 [step1完成]: 100ms
// ⏱️ [processData] 检查点 [step2完成]: 250ms
// ⚡ [processData] 450ms
```

**适用场景：**

- 复杂的多步骤操作
- 需要设置检查点的场景
- 需要手动控制计时的场景

## 实际使用示例

### 示例 1: 监控网络请求

```dart
class UserRepository {
  Future<User> getUserInfo(String userId) async {
    return AppLogger.measureAsync(
      'getUserInfo',
      () async {
        final response = await _apiClient.get('/users/$userId');
        return User.fromJson(response.data);
      },
    );
  }

  Future<List<User>> getUserList() async {
    return AppLogger.measureAsync(
      'getUserList',
      () async {
        final response = await _apiClient.get('/users');
        return (response.data as List)
            .map((json) => User.fromJson(json))
            .toList();
      },
    );
  }
}
```

**日志输出示例：**

```
⚡ [getUserInfo] 280ms
⚡ [getUserList] 520ms
```

### 示例 2: 监控数据处理

```dart
class DataProcessor {
  List<ProcessedData> processLargeDataset(List<RawData> rawData) {
    return AppLogger.measure(
      'processLargeDataset',
      () {
        return rawData.map((data) {
          // 复杂的数据处理逻辑
          return processItem(data);
        }).toList();
      },
    );
  }
}
```

**日志输出示例：**

```
🐌 [processLargeDataset] 1250ms  // 慢操作，自动警告
```

### 示例 3: 监控页面加载（带检查点）

```dart
class HomePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    final timer = AppLogger.startTimer('loadHomePage');

    try {
      // 加载用户信息
      await ref.read(userProvider.notifier).loadUserInfo();
      timer.checkpoint('用户信息加载完成');

      // 加载订单列表
      await ref.read(orderListProvider.notifier).loadOrders();
      timer.checkpoint('订单列表加载完成');

      // 加载通知数量
      await ref.read(notificationProvider.notifier).loadUnreadCount();
      timer.checkpoint('通知数量加载完成');

    } finally {
      timer.stop();
    }
  }
}
```

**日志输出示例：**

```
⏱️ 开始计时: loadHomePage
⏱️ [loadHomePage] 检查点 [用户信息加载完成]: 320ms
⏱️ [loadHomePage] 检查点 [订单列表加载完成]: 680ms
⏱️ [loadHomePage] 检查点 [通知数量加载完成]: 850ms
⚡ [loadHomePage] 850ms
```

### 示例 4: 监控数据库操作

```dart
class CacheService {
  Future<void> saveToCache(String key, dynamic data) async {
    return AppLogger.measureAsync(
      'cache_save_$key',
      () async {
        await _hive.put(key, data);
      },
    );
  }

  Future<dynamic> getFromCache(String key) async {
    return AppLogger.measureAsync(
      'cache_get_$key',
      () async {
        return await _hive.get(key);
      },
    );
  }
}
```

### 示例 5: 监控图片加载

```dart
class ImageLoader {
  Future<Uint8List> loadImage(String url) async {
    return AppLogger.measureAsync(
      'loadImage',
      () async {
        final response = await http.get(Uri.parse(url));
        return response.bodyBytes;
      },
    );
  }
}
```

## 性能统计和报告

### 获取单个操作的统计信息

```dart
// 获取某个操作的性能统计
final stats = AppLogger.getPerformanceStats('getUserInfo');

if (stats != null) {
  print('操作名称: ${stats.name}');
  print('调用次数: ${stats.totalCalls}');
  print('成功率: ${(stats.successRate * 100).toStringAsFixed(1)}%');
  print('平均耗时: ${stats.avgDuration}ms');
  print('最小耗时: ${stats.minDuration}ms');
  print('最大耗时: ${stats.maxDuration}ms');
  print('慢操作次数: ${stats.slowOperations}');
}
```

### 打印完整性能报告

```dart
// 在应用退出或调试时打印完整报告
AppLogger.printPerformanceReport();
```

**输出示例：**

```
================================================================================
📊 性能统计报告
================================================================================
生成时间: 2025-01-29 10:30:00.000
总操作数: 5

📈 getUserList
  调用次数: 15
  成功率: 100.0%
  平均耗时: 520ms
  最小耗时: 450ms
  最大耗时: 680ms

📈 getUserInfo
  调用次数: 32
  成功率: 96.9%
  平均耗时: 280ms
  最小耗时: 180ms
  最大耗时: 450ms

📈 processLargeDataset
  调用次数: 8
  成功率: 100.0%
  平均耗时: 1250ms
  最小耗时: 1100ms
  最大耗时: 1500ms
  🐌 慢操作: 8 次

📈 cache_save_userInfo
  调用次数: 10
  成功率: 100.0%
  平均耗时: 25ms
  最小耗时: 15ms
  最大耗时: 45ms

📈 loadImage
  调用次数: 24
  成功率: 95.8%
  平均耗时: 380ms
  最小耗时: 200ms
  最大耗时: 850ms
  🐌 慢操作: 2 次

================================================================================
```

### 清除性能记录

```dart
// 清除特定操作的记录
AppLogger.clearPerformanceRecords('getUserInfo');

// 清除所有性能记录
AppLogger.clearPerformanceRecords();
```

## 高级功能

### 1. 记录操作结果

```dart
// 记录操作结果（调试时使用）
final data = await AppLogger.measureAsync(
  'fetchData',
  () async => await api.getData(),
  logResult: true, // 记录返回结果
);

// 日志会包含返回结果（仅在开发环境）
```

### 2. 错误处理

```dart
// 操作失败时会自动记录错误
try {
  final result = await AppLogger.measureAsync(
    'riskyOperation',
    () async {
      // 可能失败的操作
      throw Exception('Operation failed');
    },
  );
} catch (e) {
  // 错误已被自动记录
  // 日志输出：❌ [riskyOperation] 50ms
}
```

### 3. 检查当前耗时

```dart
final timer = AppLogger.startTimer('longOperation');

await step1();
print('已耗时: ${timer.elapsedMilliseconds}ms');

await step2();
print('已耗时: ${timer.elapsedSeconds}秒');

timer.stop();
```

### 4. 重置计时器

```dart
final timer = AppLogger.startTimer('retryOperation', autoLog: false);

for (var i = 0; i < 3; i++) {
  try {
    await performOperation();
    break;
  } catch (e) {
    if (i < 2) {
      timer.reset(); // 重置计时器，重新计时
    }
  }
}

timer.stop();
```

## 配置选项

### 慢操作阈值

默认阈值是 **1000ms（1秒）**，超过此阈值的操作会被标记为慢操作（🐌）。

```dart
// 当前阈值（只读）
final threshold = PerformanceMonitor.slowThreshold; // 1000ms
```

### 记录数量限制

每个操作最多保留 **100 条**性能记录，超过后自动删除最旧的记录。

```dart
// 内部配置（只读）
static const int _maxRecordsPerOperation = 100;
```

## 最佳实践

### 1. 命名规范

```dart
// ✅ 好的命名
AppLogger.measureAsync('fetchUserInfo', ...);
AppLogger.measureAsync('saveOrderToCache', ...);
AppLogger.measureAsync('processPaymentData', ...);

// ❌ 不好的命名
AppLogger.measureAsync('getData', ...);  // 太模糊
AppLogger.measureAsync('func1', ...);    // 无意义
AppLogger.measureAsync('a', ...);        // 太短
```

**建议：**

- 使用描述性的名称
- 使用驼峰命名法
- 包含操作的类型和目标

### 2. 选择合适的监控方式

```dart
// ✅ 简单操作 - 使用 measure/measureAsync
final result = await AppLogger.measureAsync('fetchData', () => api.getData());

// ✅ 复杂操作 - 使用 PerformanceTimer
final timer = AppLogger.startTimer('complexProcess');
await step1();
timer.checkpoint('step1');
await step2();
timer.checkpoint('step2');
timer.stop();
```

### 3. 避免过度监控

```dart
// ❌ 不要监控每个小操作
AppLogger.measure('add', () => a + b);  // 太细粒度

// ✅ 监控有意义的操作
AppLogger.measureAsync('calculateTotalPrice', () async {
  final items = await getItems();
  return items.fold(0.0, (sum, item) => sum + item.price);
});
```

### 4. 在适当的位置打印报告

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 应用进入后台时打印性能报告
      AppLogger.printPerformanceReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}
```

## 注意事项

### 1. 性能开销

- **极小开销**：性能监控本身的开销非常小（< 1ms）
- **内存占用**：每个操作最多保留 100 条记录
- **适用场景**：可以放心地在生产环境使用

### 2. 日志级别

```dart
// 成功的快速操作（< 1秒）
⚡ [operation] 500ms  // DEBUG 级别（仅开发环境）

// 成功的慢操作（≥ 1秒）
🐌 [operation] 1200ms  // WARNING 级别（所有环境）

// 失败的操作
❌ [operation] 300ms  // ERROR 级别（所有环境）
```

### 3. 并发操作

```dart
// ✅ 支持并发监控
final futures = [
  AppLogger.measureAsync('op1', () => operation1()),
  AppLogger.measureAsync('op2', () => operation2()),
  AppLogger.measureAsync('op3', () => operation3()),
];

await Future.wait(futures);

// 每个操作都会独立计时和记录
```

### 4. 嵌套监控

```dart
// ✅ 支持嵌套监控
Future<Data> loadData() async {
  return AppLogger.measureAsync('loadData', () async {
    final raw = await AppLogger.measureAsync(
      'fetchRawData',
      () => api.getData(),
    );
    
    return AppLogger.measure(
      'processData',
      () => processData(raw),
    );
  });
}

// 日志输出：
// ⚡ [fetchRawData] 320ms
// ⚡ [processData] 150ms
// ⚡ [loadData] 470ms
```

## 故障排查

### 问题 1: 没有日志输出

**原因：** 开发环境下，快速操作（< 1秒）的日志是 DEBUG 级别。

**解决方案：**

```dart
// 方式 1: 降低日志级别
AppLogger.initialize(logLevel: 'debug');

// 方式 2: 查看慢操作（≥ 1秒）的日志
// 这些日志是 WARNING 级别，始终会输出
```

### 问题 2: 计时不准确

**原因：** Timer 未正确停止。

**解决方案：**

```dart
// ✅ 确保在 finally 中停止计时
final timer = AppLogger.startTimer('operation');
try {
  await performOperation();
} finally {
  timer.stop(); // 确保总是停止
}
```

### 问题 3: 内存占用过大

**原因：** 监控了太多不同名称的操作。

**解决方案：**

```dart
// 定期清理性能记录
AppLogger.clearPerformanceRecords();

// 或者只清理特定操作
AppLogger.clearPerformanceRecords('oldOperation');
```

## 与其他工具集成

### 与 Firebase Performance 集成

```dart
Future<T> measureWithFirebase<T>(
  String name,
  Future<T> Function() operation,
) async {
  final trace = FirebasePerformance.instance.newTrace(name);
  await trace.start();
  
  try {
    return await AppLogger.measureAsync(name, operation);
  } finally {
    await trace.stop();
  }
}
```

### 与 Sentry 集成

```dart
Future<T> measureWithSentry<T>(
  String name,
  Future<T> Function() operation,
) async {
  final transaction = Sentry.startTransaction(name, 'task');
  
  try {
    return await AppLogger.measureAsync(name, operation);
  } finally {
    await transaction.finish();
  }
}
```

## 总结

`PerformanceMonitor` 提供了一个简单而强大的性能监控方案：

- ✅ **易于使用** - 3 种使用方式，适应不同场景
- ✅ **自动化** - 自动记录、统计、识别慢操作
- ✅ **轻量级** - 极小的性能开销
- ✅ **生产就绪** - 可直接用于生产环境

立即开始使用性能监控，优化您的应用性能！

---

**相关文档：**

- [日志系统使用指南](./LOGGING_SYSTEM_GUIDE.md)
- [Talker 集成文档](./TALKER_INTEGRATION.md)
- [Talker 官方文档](https://github.com/Frezyx/talker)

**更新日期：** 2026-03-17
