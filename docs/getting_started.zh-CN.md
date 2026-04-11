# 快速上手

## 前置条件

- **Flutter** 3.8 或更新版本（推荐稳定频道）
- **Dart** 3.8.0+（随 Flutter 捆绑，需满足 `pubspec.yaml` 中的 `environment.sdk`）
- **just**（可选但推荐）— [https://github.com/casey/just](https://github.com/casey/just)
- iOS 和 Android 开发需要对应的 Xcode / Android Studio 工具链

验证版本：

```bash
flutter --version
dart --version
```

## 克隆与初始化

```bash
git clone <你的仓库地址> flutter_clean_arch_template
cd flutter_clean_arch_template
flutter pub get
```

如果你要基于此模版创建**新应用**，在深度定制之前运行交互式配置脚本：

```bash
dart run tool/setup.dart
```

脚本会提示输入：

- 项目名称（snake_case，如 `my_awesome_app`）
- 组织名（反向域名，如 `com.example`）
- 应用显示名和描述

脚本会自动更新 Dart 包导入、Android/iOS 标识符和相关元数据。完成后执行代码生成（见下节）。

## 运行配置脚本

```bash
dart run tool/setup.dart
```

按提示操作，输入 `y` 确认应用更改。脚本会在流程中自动执行 `flutter pub get`。如果跳过重命名，模版仍可以默认包名 `flutter_clean_arch_template` 正常使用。

## 代码生成

本项目依赖 **build_runner** 生成以下文件：

- Riverpod（`*.g.dart`）
- Freezed / json_serializable（`*.freezed.dart`、`*.g.dart`）
- Injectable（`service_locator.config.dart`）
- AutoRoute（`app_router.gr.dart`）

一次性生成：

```bash
just gen
```

等价命令：

```bash
dart run build_runner build --delete-conflicting-outputs
```

开发时持续监听：

```bash
just gen-watch
```

## 运行应用

**开发环境**（默认后端/环境标志）：

```bash
just dev
```

手动等价命令：

```bash
flutter run --dart-define=ENVIRONMENT=development
```

其他命令（定义在 [`justfile`](../justfile) 中）：

- `just staging` — `ENVIRONMENT=staging`
- `just prod-debug` — `ENVIRONMENT=production`（Debug 模式）
- `just release` — Release 模式 + production 环境
- `just run <env> <device-id>` — 自定义组合

## 环境配置

- 环境文件位于 **`assets/env/`**（如 `.env.development`）。通过 **`flutter_dotenv`** 和 `lib/core/env/` 中的 **`AppConfig`** / 环境管理器加载
- 运行时通过 **`--dart-define=ENVIRONMENT=...`** 选择环境（`development` | `staging` | `production`）
- 添加新的环境文件后，确保在 `pubspec.yaml` 的 `flutter.assets` 中列出

### 认证与 Demo 环境变量

| 变量 | 可选值 | 默认值 | 说明 |
|------|--------|--------|------|
| `AUTH_MODE` | `required` / `optional` | `required` | `required` = 所有页面需登录；`optional` = 首页免登录，仅部分页面需要登录 |
| `MOCK_AUTH` | `true` / `false` | `true`（dev） | 为 `true` 时登录使用 Mock 数据，登录页显示「Demo Login」按钮；设为 `false` 使用真实 API |

示例 `.env.development`：

```env
AUTH_MODE=required
MOCK_AUTH=true
```

**请勿提交敏感信息。** 使用 CI 变量或本地未跟踪的覆盖文件存放敏感值。

## 应用资源（图标 & 启动屏）

模版包含两个代码生成工具的配置文件，用于生成平台原生资源：

- **`flutter_launcher_icons.yaml`** — 从单一源 PNG 为所有平台生成启动图标
- **`flutter_native_splash.yaml`** — 生成在 Flutter 渲染前显示的原生启动屏

```bash
just gen-icon     # 生成启动图标
just gen-splash   # 生成原生启动屏
```

将源图片放在 `assets/icon/` 和 `assets/splash/` 目录下。详细配置选项、素材准备和平台特殊说明见 [app_resources.zh-CN.md](app_resources.zh-CN.md)。

## 开发流程

1. 为你的工作创建分支
2. 在 `lib/features/...` 中按照 [architecture.zh-CN.md](architecture.zh-CN.md) 实现功能
3. 修改带注解的类（Riverpod、Freezed、Injectable、路由）后运行 **`just gen`**
4. 提交 PR 前运行 **`just analyze`** 和 **`just test`**
5. 如果代码生成或插件状态不同步，使用 **`just clean`** 然后重新 **`just gen`**

功能开发完整教程：[create_new_feature.zh-CN.md](create_new_feature.zh-CN.md)
