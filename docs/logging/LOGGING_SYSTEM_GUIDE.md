# 日志系统使用指南

## 📋 概述

本项目采用基于 **Talker** 的统一日志系统，提供完整的日志记录、过滤、格式化和可视化功能。

## 🏗️ 系统架构

```
lib/core/logger/
├── app_logger.dart                    # 统一日志门面
├── talker_config.dart                 # Talker 配置
├── log_context.dart                   # 日志上下文信息
├── performance_monitor.dart           # 性能监控
├── observers/
│   ├── console_observer.dart          # 控制台输出
│   ├── file_observer.dart             # 文件持久化
│   └── third_party_observer.dart      # 第三方监控上报（可选）
├── filters/
│   ├── log_level_filter.dart          # 日志级别过滤
│   └── sensitive_filter.dart          # 敏感信息过滤
└── formatters/
    └── log_formatter.dart             # 日志格式化
```

## 🚀 快速开始

### 1. 日志初始化

日志系统在应用启动时自动初始化（`lib/main.dart`）：

```dart
Future<void> _initializeApp(WidgetsBinding widgetsBinding) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 注意：此时 AppLogger 未初始化，使用早期日志缓冲区机制
  final timer = AppLogger.startTimer('应用启动初始化');

  // 1. 初始化环境配置（最先执行）
  await EnvConfigManager.initialize();

  // 2. 初始化日志系统（传入环境配置参数）
  await AppLogger.initialize(
    environment: AppConfig.environment,
    logLevel: AppConfig.logLevel,
  );

  timer.checkpoint('环境配置和日志系统初始化完成');

  // ... 其他初始化
  await ServiceLocator.initialize();

  timer.stop();
}
```

> **早期日志缓冲区**：在 `AppLogger.initialize()` 调用前产生的日志会被缓存到内部缓冲区（最多 100 条），初始化完成后自动转储到 Talker。

### 2. 基本使用

```dart
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

// Debug 日志
AppLogger.debug('调试信息');
AppLogger.d('调试信息');  // 简写

// Info 日志
AppLogger.info('普通信息');
AppLogger.i('普通信息');  // 简写

// Warning 日志
AppLogger.warning('警告信息');
AppLogger.w('警告信息');  // 简写

// Error 日志
AppLogger.error('错误信息');
AppLogger.e('错误信息');  // 简写

// Fatal/Critical 日志
AppLogger.fatal('致命错误');
AppLogger.f('致命错误');  // 简写
```

### 3. 带错误对象的日志

```dart
try {
  // 可能抛出异常的代码
  await someOperation();
} catch (error, stackTrace) {
  AppLogger.error('操作失败', error: error, stackTrace: stackTrace);
}
```

### 4. HTTP 日志

```dart
AppLogger.http('请求完成', data: {
  'request': requestData,
  'response': responseData,
});
```

### 5. 异常日志

```dart
AppLogger.exception(
  exception,
  stackTrace,
  message: '用户操作异常',
  context: {'userId': '123', 'action': 'submit'},
);
```

## 📊 日志级别

| 级别 | 方法 | 使用场景 |
|------|------|----------|
| DEBUG | `debug()` / `d()` | 开发调试信息，生产环境不输出 |
| INFO | `info()` / `i()` | 普通信息，记录关键流程 |
| WARNING | `warning()` / `w()` | 警告信息，需要注意但不影响运行 |
| ERROR | `error()` / `e()` | 错误信息，功能异常但应用可继续 |
| FATAL | `fatal()` / `f()` | 致命错误，可能导致应用崩溃 |

## 🎯 环境配置

不同环境的日志配置（`assets/env/`）：

### 开发环境 (.env.development)

```env
LOG_LEVEL=debug
ENABLE_CONSOLE_LOG=true
ENABLE_FILE_LOG=false
ENABLE_TALKER_SCREEN=true
LOG_MAX_HISTORY=1000
```

### 预发布环境 (.env.staging)

```env
LOG_LEVEL=info
ENABLE_CONSOLE_LOG=false
ENABLE_FILE_LOG=true
ENABLE_TALKER_SCREEN=true
LOG_MAX_HISTORY=500
```

### 生产环境 (.env.production)

```env
LOG_LEVEL=error
ENABLE_CONSOLE_LOG=false
ENABLE_FILE_LOG=true
ENABLE_TALKER_SCREEN=false
LOG_MAX_HISTORY=200
```

## 🔍 日志可视化

### 访问日志查看器

在调试模式下（`AppConfig.enableTalkerScreen == true`），可以通过以下方式访问 Talker 日志查看器：

1. **从个人中心页面**：
   - 进入"我的"页面
   - 点击"日志查看器"（仅在 `enableTalkerScreen` 为 true 时显示）

2. **直接导航（auto_route）**：

```dart
// 跳转到日志查看器
context.router.push(const LoggerViewerRoute());
```

日志查看器页面位于 `lib/features/app/presentation/pages/settings_page/logger_viewer_page.dart`，使用 `TalkerScreen(talker: AppLogger.talker)` 渲染。

### 日志查看器功能

- 📋 查看所有历史日志
- 🔍 搜索和过滤日志
- 📊 按级别筛选
- 📤 分享日志
- 🗑️ 清空日志历史

## 🔒 安全特性

### 敏感信息自动过滤

日志系统会自动过滤以下敏感信息：

- 密码 (password, passwd, pwd)
- 令牌 (token, access_token, refresh_token)
- API 密钥 (api_key, apikey, secret)
- 授权信息 (authorization, auth)
- Cookie 和 Session
- 信用卡信息 (credit_card, cvv)
- 身份证号 (id_card, ssn)

示例：

```dart
// 原始日志
AppLogger.info('登录成功: {"password": "123456", "name": "张三"}');

// 实际输出
AppLogger.info('登录成功: {"password": "***HIDDEN***", "name": "张三"}');
```

## 📁 日志持久化

### 文件位置

日志文件保存在应用文档目录：

```
{应用文档目录}/logs/
├── app_log_2025-01-29T14:30:00.log
├── app_log_2025-01-29T15:00:00.log
└── ...
```

### 日志轮转

- **最大文件大小**：10MB
- **最大文件数量**：5个
- **轮转策略**：文件达到最大大小时自动创建新文件，超过数量限制时删除最旧的文件

## 🔧 高级用法

### 更新日志上下文

```dart
// 用户登录后更新上下文
AppLogger.updateContext(
  userId: user.id,
  custom: {
    'userRole': user.role,
    'tenantId': user.tenantId,
  },
);
```

### 获取 Talker 实例

```dart
// 用于高级操作
final talker = AppLogger.talker;

// 清空日志历史
AppLogger.clear();

// 获取日志历史
final history = AppLogger.history;
```

### 自定义日志类型

```dart
// 创建自定义日志类型
class CustomLog extends TalkerLog {
  CustomLog(String message) : super(message);

  @override
  String get key => 'custom';

  @override
  String get title => 'CUSTOM';

  @override
  AnsiPen get pen => AnsiPen()..magenta();
}

// 使用自定义日志
AppLogger.talker.logTyped(CustomLog('自定义日志'));
```

## 📋 最佳实践

### 1. 日志消息规范

```dart
// ✅ 推荐：清晰描述操作和结果
AppLogger.info('用户登录成功: userId=${user.id}');
AppLogger.error('获取订单列表失败', error: e);

// ❌ 避免：信息不明确
AppLogger.info('成功');
AppLogger.error('失败');
```

### 2. 日志级别选择

```dart
// ✅ 正确使用级别
AppLogger.debug('进入订单详情页: orderId=$orderId');  // 调试信息
AppLogger.info('订单创建成功: orderId=$orderId');     // 关键流程
AppLogger.warning('网络请求重试: attempt=$attempt');  // 警告信息
AppLogger.error('订单创建失败', error: e);            // 错误信息
AppLogger.fatal('数据库连接失败', error: e);          // 致命错误

// ❌ 避免：滥用日志级别
AppLogger.fatal('用户点击按钮');  // 普通操作不应使用 fatal
```

### 3. 性能考虑

```dart
// ✅ 避免在循环中频繁记录日志
final items = await fetchItems();
AppLogger.info('获取到 ${items.length} 条数据');

// ❌ 避免
for (final item in items) {
  AppLogger.debug('处理项目: $item');  // 可能产生大量日志
}
```

### 4. 不要记录敏感信息

```dart
// ✅ 推荐：敏感信息会自动过滤
AppLogger.info('登录请求: $requestData');

// ✅ 额外保护：手动脱敏
AppLogger.info('用户手机号: ${phone.substring(0, 3)}****${phone.substring(7)}');

// ❌ 避免：直接记录完整敏感信息（虽然会被过滤，但最好主动脱敏）
```

## 🔗 相关文档

- [Talker 集成文档](./TALKER_INTEGRATION.md)
- [Talker Review 报告](./TALKER_REVIEW_REPORT.md)
- [性能监控使用指南](./PERFORMANCE_MONITORING_GUIDE.md)

## 📝 常见问题

### Q: 为什么我的日志没有输出到控制台？

A: 检查以下几点：

1. 确保日志级别设置正确（环境配置中的 `LOG_LEVEL`）
2. 生产环境默认不输出到控制台
3. 检查是否调用了 `AppLogger.initialize()`

### Q: 如何查看生产环境的日志？

A: 生产环境的日志会：

1. 保存到本地文件（`{应用文档目录}/logs/`）
2. 错误和致命日志自动上报到第三方监控平台（如已配置）

### Q: 日志文件占用太多空间怎么办？

A: 日志系统有自动清理机制：

- 单个文件最大 10MB
- 最多保留 5 个文件
- 超过限制自动删除最旧的文件

### Q: 如何在测试中模拟日志？

A: 可以通过获取 Talker 实例进行测试：

```dart
// 在测试中
final logs = AppLogger.history;
expect(logs.any((log) => log.message.contains('测试消息')), isTrue);
```

## 🚨 注意事项

1. **不要在日志消息中包含用户隐私信息**（系统会过滤，但最好主动避免）
2. **避免在生产环境使用 debug 级别日志**（会产生大量无用信息）
3. **日志文件会占用存储空间**（虽然有自动清理，但注意控制日志量）
4. **日志初始化必须在使用前完成**（在 `main.dart` 中已自动初始化）
5. **不要在热路径中记录大量日志**（影响性能）

## 🎉 迁移说明

### 从旧的 Logger 迁移

旧代码（已弃用）：

```dart
import 'package:flutter_clean_arch_template/shared/utils/logger.dart';
// 或
import 'package:flutter_clean_arch_template/shared/utils/logger/app_logger.dart';
```

新代码：

```dart
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

AppLogger.debug('消息');  // API 保持兼容，只需更新导入路径
```

### 替换 print 语句

```dart
// 旧代码
print('调试信息');
debugPrint('调试信息');

// 新代码
AppLogger.debug('调试信息');
AppLogger.info('普通信息');
AppLogger.error('错误信息');
```

---

**更新日期**：2026-03-17  
**版本**：1.1.0  
**维护者**：Template Team
