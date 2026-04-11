# 环境配置管理完整指南

## 📋 目录

- [概述](#概述)
- [文件结构](#文件结构)  
- [核心功能](#核心功能)
- [配置管理界面](#配置管理界面)
- [代码使用方法](#代码使用方法)
- [环境切换机制](#环境切换机制)
- [配置文件说明](#配置文件说明)
- [开发指南](#开发指南)
- [生产环境保护](#生产环境保护)
- [故障排除](#故障排除)

---

## 概述

本系统基于 `flutter_dotenv 6.0.0+` 实现了完整的环境配置管理功能，支持：

- 🔄 **环境选择持久化**：用户选择的环境自动保存，重启后恢复
- 🎛️ **隐藏配置管理界面**：登录页面连续点击5次logo进入
- 🔒 **生产环境保护**：通过 `EDIT_ENV` 环境变量控制编辑权限
- 🏗️ **结构化环境类型**：使用 `EnvType` 枚举管理环境配置

## 📁 文件结构

```
lib/core/env/
├── env_config_manager.dart     # 环境配置管理器（核心）
└── app_config.dart            # 应用配置访问类

lib/features/pages/config_management/
└── config_management_page.dart # 配置管理界面

lib/core/constants/
└── storage_keys.dart          # 存储键定义

assets/env/
├── .env                       # 基础配置文件
├── .env.development                  # 开发环境配置
├── .env.staging              # 预发布环境配置
└── .env.production                 # 生产环境配置
```

## 核心功能

### ✨ 环境选择持久化

#### 环境优先级（修正版）

系统按以下优先级确定当前环境：

1. **📱 本地存储**：用户通过界面选择并保存的环境（仅在 `EDIT_ENV=true` 时生效,最高优先级，强制覆盖）
2. **🔧 环境变量**：`--dart-define=ENVIRONMENT=xxx`
3. **🔧 命令行参数**：`--dart-define=FLAVOR=xxx`
4. **⚙️ 编译模式默认**：Debug=development, Profile=staging, Release=production

#### EnvType 枚举定义

```dart
enum EnvType {
  development('development', 'dev', '开发', 'assets/env/.env.development'),
  staging('staging', 'staging', '预发布', 'assets/env/.env.staging'),
  production('production', 'prod', '生产', 'assets/env/.env.production');

  const EnvType(this.value, this.flavor, this.displayName, this.envFile);

  final String value;        // 环境标识符
  final String flavor;       // 命令行参数别名
  final String displayName;  // 界面显示名称
  final String envFile;      // 配置文件路径
}
```

### 🛡️ 生产环境保护

```bash
# 允许编辑环境（开发/测试环境）
flutter run --dart-define=EDIT_ENV=true

# 禁止编辑环境（生产环境，默认）
flutter run --dart-define=EDIT_ENV=false
```

当 `EDIT_ENV=false` 时：

- ❌ 无法通过界面切换环境
- ❌ 无法保存环境选择
- ❌ 界面显示"环境编辑已禁用"提示

## 🎛️ 配置管理界面

### 进入方式

1. 在登录页面连续快速点击**5次**应用Logo
2. 2秒内完成点击，否则计数重置
3. 自动跳转到配置管理页面

### 界面功能

#### 1. 环境切换区域

- **当前环境显示**：显示当前使用的环境
- **环境按钮**：开发/测试/生产三个环境切换按钮
- **状态指示**：当前选中环境高亮显示
- **重置按钮**：一键清除保存的环境选择

#### 2. 当前配置区域

- **配置展示**：显示所有当前环境变量
- **敏感信息脱敏**：包含敏感关键字的值显示为 `***HIDDEN***`
- **刷新功能**：手动重新加载配置
- **搜索功能**：快速查找配置项

#### 3. 重启提示机制

环境切换后会显示重启提示对话框：

```dart
void _showRestartDialog(String environment) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('环境切换成功'),
        content: Text('已切换到 $environment 环境\n\n请手动重启应用以使配置完全生效。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();  // 退出应用
            },
            child: const Text('退出应用'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后重启'),
          ),
        ],
      );
    },
  );
}
```

## 💻 代码使用方法

### 1. 使用 AppConfig 类（推荐）

```dart
import 'package:flutter_clean_arch_template/core/env/app_config.dart';

// 获取API地址
final apiUrl = AppConfig.baseUrl;

// 获取客户端ID
final clientId = AppConfig.clientId;

// 检查功能开关
if (AppConfig.enableAnalytics) {
  // 初始化分析功能
}

// 获取网络超时配置
final timeout = AppConfig.connectTimeout;
```

### 2. 直接使用 EnvConfigManager

```dart
import 'package:flutter_clean_arch_template/core/env/env_config_manager.dart';

// 获取字符串值
final apiUrl = EnvConfigManager.getString('API_BASE_URL');

// 获取布尔值（带默认值）
final enableFeature = EnvConfigManager.getBool('ENABLE_FEATURE', defaultValue: false);

// 获取整数值
final timeout = EnvConfigManager.getInt('CONNECT_TIMEOUT', defaultValue: 30000);

// 获取浮点数值
final version = EnvConfigManager.getDouble('API_VERSION', defaultValue: 1.0);

// 检查配置项是否存在
if (EnvConfigManager.hasKey('DEBUG_MODE')) {
  // 处理调试模式
}
```

### 3. 环境管理操作

```dart
// 保存环境选择（仅在 EDIT_ENV=true 时有效）
await EnvConfigManager.saveSelectedEnvironment('development');

// 获取保存的环境选择
final savedEnv = EnvConfigManager.getSavedEnvironment();

// 清除保存的环境选择
await EnvConfigManager.clearSavedEnvironment();

// 检查当前环境
final currentEnv = EnvConfigManager.getCurrentEnvironment();

// 检查是否允许编辑环境
final canEdit = EnvConfigManager.checkCanEditEnv();
```

## 🔄 环境切换机制

### 工作流程

1. **环境确定**: 根据优先级确定当前环境
2. **配置文件加载**:
   - 首先加载基础 `.env` 文件
   - 然后加载环境特定配置文件
   - 使用 `overrideWithFiles` 实现配置覆盖
3. **配置合并**: 环境特定配置覆盖基础配置
4. **初始化完成**: 配置可供应用使用

### 使用场景

#### 开发场景

```bash
# 开发者日常开发
flutter run --dart-define=EDIT_ENV=true

# 1. 进入配置管理界面
# 2. 选择"开发"环境
# 3. 环境选择自动保存
# 4. 后续启动自动使用开发环境
```

#### 测试场景

```bash
# 测试人员验证功能
flutter run --dart-define=EDIT_ENV=true

# 1. 选择"测试"环境
# 2. 验证功能在测试环境的表现
# 3. 环境选择持久保存
```

#### 生产发布场景

```bash
# 强制使用生产环境构建
flutter build apk --dart-define=ENVIRONMENT=production
```

## 📝 配置文件说明

### .env（基础配置）

包含所有环境通用的默认配置值：

```bash
# 应用基本信息

ENVIRONMENT=development

# API配置
API_BASE_URL=https://api-dev.example.com
API_TIMEOUT=30000

# 功能开关
ENABLE_DEBUG_MODE=true
ENABLE_ANALYTICS=false
ENABLE_CRASH_REPORTING=false

# 第三方服务配置
LOG_LEVEL=debug
```

### .env.development（开发环境）

开发环境专用配置：

```bash
# 开发环境标识
ENVIRONMENT=development

# 开发服务器配置
API_BASE_URL=https://api-dev.example.com
API_TIMEOUT=30000

# 开发功能开关
# ENABLE_DEBUG_MODE=true
# ENABLE_MOCK_DATA=true
# DEBUG_NETWORK_REQUESTS=true

# 测试数据
# TEST_USER_PHONE=13800138000
# TEST_SMS_CODE=123456
```

### .env.staging（预发布环境）

测试环境配置：

```bash
# 预发布环境标识
ENVIRONMENT=staging

# 预发布服务器配置
API_BASE_URL=https://api-staging.example.com
API_TIMEOUT=15000

# 预发布功能配置
# ENABLE_DEBUG_MODE=false
# ENABLE_ANALYTICS=true
# ENABLE_TEST_FEATURES=true

# 日志配置
LOG_LEVEL=info
```

### .env.prod（生产环境）

生产环境配置：

```bash
# 生产环境标识
ENVIRONMENT=production

# 生产服务器配置
API_BASE_URL=https://api.example.com
API_TIMEOUT=10000

# 生产功能配置
# ENABLE_DEBUG_MODE=false
# ENABLE_ANALYTICS=true
# ENABLE_SECURITY_CHECKS=true

# 生产日志配置
LOG_LEVEL=warning
```

## 🛠️ 开发指南

### 添加新的配置项

1. **在配置文件中添加**:

   ```bash
   # .env
   NEW_FEATURE_ENABLED=false
   
   # .env.development  
   NEW_FEATURE_ENABLED=true
   ```

2. **在 AppConfig 中添加访问器**:

   ```dart
   /// 是否启用新功能
   static bool get enableNewFeature {
     return EnvConfigManager.getBool('NEW_FEATURE_ENABLED', defaultValue: false);
   }
   ```

3. **在代码中使用**:

   ```dart
   if (AppConfig.enableNewFeature) {
     // 新功能逻辑
   }
   ```

### 调试配置

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_clean_arch_template/core/env/env_config_manager.dart';

if (kDebugMode) {
  // 打印所有环境变量（脱敏版本）
  final safeVars = EnvConfigManager.getSafeEnvVarsForLogging();
  safeVars.forEach((key, value) {
    print('$key = $value');
  });
  
  // 检查当前环境
  print('当前环境: ${EnvConfigManager.getCurrentEnvironment()}');
  
  // 检查是否允许编辑
  print('允许编辑环境: ${EnvConfigManager.checkCanEditEnv()}');
}
```

### 扩展环境类型

如需添加新的环境类型（如预发布环境）：

```dart
enum EnvType {
  development('development', 'dev', '开发', 'assets/env/.env.dev'),
  preproduction('test', 'test', '预发布', 'assets/env/.env.test'),  // 新增
  staging('staging', 'staging', '预发布', 'assets/env/.env.staging'),
  production('production', 'prod', '生产', 'assets/env/.env.prod');
  
  // ... 其他代码保持不变
}
```

## 🛡️ 生产环境保护

### 保护机制

1. **编辑权限控制**

   ```bash
   # 生产构建时禁用环境编辑
   flutter build apk --dart-define=EDIT_ENV=false
   ```

2. **环境强制覆盖**

   ```bash
   # 强制使用指定环境，忽略用户选择
   flutter build apk --dart-define=ENVIRONMENT=production
   ```

3. **敏感信息脱敏**
   - 自动识别敏感关键字：`CLIENT_ID`, `API_KEY`, `SECRET`, `TOKEN`, `PASSWORD`
   - 配置显示时替换为 `***HIDDEN***`

### 最佳实践

#### 开发环境

- 设置 `EDIT_ENV=true` 允许环境切换
- 使用详细的日志级别
- 启用调试功能和模拟数据

#### 测试环境  

- 设置 `EDIT_ENV=true` 便于测试不同环境
- 启用分析和监控功能
- 模拟生产环境配置

#### 生产环境

- 设置 `EDIT_ENV=false` 禁用环境编辑
- 使用环境变量强制指定环境
- 启用所有安全检查和监控

## 🔒 安全注意事项

1. **敏感信息管理**
   - ❌ 不要在配置文件中存储密码、私钥等敏感信息
   - ✅ 使用环境变量或安全的密钥管理服务
   - ✅ 利用系统的脱敏显示功能

2. **版本控制**
   - ✅ 配置文件模板可以提交到版本控制
   - ❌ 包含真实敏感数据的文件不要提交
   - ✅ 使用 `.env.local` 文件存储本地敏感配置

3. **权限控制**
   - ✅ 生产环境构建时设置 `EDIT_ENV=false`
   - ✅ 使用强制环境变量覆盖用户选择
   - ✅ 定期审查配置文件内容

## 🐛 故障排除

### 常见问题

#### 1. 环境选择未保存

- **现象**: 重启后环境恢复到默认
- **原因**:
  - 环境切换时发生异常
  - `EDIT_ENV=false` 禁用了编辑功能
  - SharedPreferences 初始化失败
- **解决**:
  1. 检查是否设置了 `EDIT_ENV=true`
  2. 查看控制台是否有错误日志
  3. 确认切换时显示了成功提示

#### 2. 环境优先级异常  

- **现象**: 界面选择被忽略
- **排查顺序**:
  1. 检查是否设置了 `--dart-define=ENVIRONMENT=xxx`
  2. 检查是否设置了 `--dart-define=FLAVOR=xxx`
  3. 确认 `EDIT_ENV=true`
  4. 验证本地存储中的环境选择

#### 3. 配置文件加载失败

- **现象**: 应用启动报错或配置为空
- **解决**:
  1. 检查 `assets/env/` 目录是否存在配置文件
  2. 确认 `pubspec.yaml` 中包含 `assets/env/` 配置
  3. 验证配置文件格式正确（`KEY=VALUE`）
  4. 运行 `flutter clean && flutter pub get`

#### 4. 重启提示无效

- **现象**: 环境切换后配置未生效
- **解决**:
  1. 手动完全重启应用（不是热重启）
  2. 检查是否有更高优先级的环境设置
  3. 清除应用数据重新测试

### 调试方法

#### 1. 检查环境状态

```dart
// 检查当前环境
print('当前环境: ${EnvConfigManager.getCurrentEnvironment()}');

// 检查保存的环境
print('保存的环境: ${EnvConfigManager.getSavedEnvironment()}');

// 检查编辑权限
print('允许编辑: ${EnvConfigManager.checkCanEditEnv()}');

// 检查特定配置
print('API地址: ${EnvConfigManager.getString('API_BASE_URL')}');
```

#### 2. 手动重置环境

```dart
// 清除保存的环境选择
await EnvConfigManager.clearSavedEnvironment();

// 重新初始化
EnvConfigManager.reset();
await EnvConfigManager.initialize();
```

#### 3. 查看所有配置

```dart
// 获取脱敏后的所有配置
final safeVars = EnvConfigManager.getSafeEnvVarsForLogging();
safeVars.forEach((key, value) => print('$key = $value'));
```

## 📚 版本历史

### v3.0.0 - 生产环境保护与结构优化

- ✅ 新增 `EnvType` 枚举管理环境类型
- ✅ 新增 `EDIT_ENV` 环境变量控制编辑权限
- ✅ 修正环境优先级逻辑
- ✅ 优化重启提示用户体验
- ✅ 直接使用 SharedPreferences 避免循环依赖

### v2.0.0 - 环境选择持久化

- ✅ 新增环境选择自动保存功能
- ✅ 新增重置到默认环境功能  
- ✅ 调整应用启动初始化顺序
- ✅ 更新环境确定优先级逻辑

### v1.0.0 - 基础配置管理

- ✅ 登录页面隐藏入口
- ✅ 配置管理界面
- ✅ 环境切换功能
- ✅ 配置文件管理

## 🚀 扩展功能建议

### 可能的增强

1. **配置模板**: 预设常用环境配置组合
2. **配置同步**: 支持团队配置云端同步
3. **配置验证**: 添加配置项格式和有效性验证
4. **使用统计**: 记录环境使用频率和切换历史
5. **快捷切换**: 添加环境快速切换快捷方式
6. **热重启**: 集成 restart 包实现配置变更后的热重启

### 集成建议

1. **CI/CD 集成**: 自动化配置文件部署和验证
2. **监控集成**: 环境切换行为和配置加载监控
3. **文档自动化**: 根据配置文件自动生成文档
4. **测试覆盖**: 添加环境管理功能的自动化测试

---

## 🔗 相关文档

- [Flutter Dotenv 官方文档](https://pub.dev/packages/flutter_dotenv)
- [应用配置类参考](../config/env/app_config.dart)
- [存储服务文档](../core/storage/)
- [路由配置文档](../config/routes/)

---

*最后更新: 2025年9月*
