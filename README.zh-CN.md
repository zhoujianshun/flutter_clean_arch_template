# Flutter Clean Architecture 项目模版

<!-- 徽章区域 -->
<!--
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
-->

一个**生产级** Flutter 项目模版，采用 **Feature-First（功能优先）** + **DDD 领域驱动** + **Clean Architecture 整洁架构**，集成 Riverpod、AutoRoute、GetIt、Freezed、Dio 等主流技术栈，并内置 50+ 可复用 UI 组件。

## 特性

- **Clean Architecture** — 关注点分离，层级职责清晰，易于测试
- **Feature-First 结构** — 每个功能模块独立放置在 `lib/features/<feature>/` 下
- **Riverpod 3.0+** — 基于代码生成的 Provider（`riverpod_annotation` / `riverpod_generator`）
- **AutoRoute** — 类型安全、声明式导航，路由自动生成
- **GetIt + Injectable** — 编译时友好的依赖注入
- **Dio** — HTTP 客户端，含拦截器、重试、连接检测、Token 管理
- **Freezed** — 不可变数据模型和代数数据类型
- **Dartz Either** — Repository 层显式的成功/失败处理
- **多环境支持** — 通过 `--dart-define` 切换 `development` / `staging` / `production`
- **双认证模式** — `required`（强制登录）或 `optional`（免登录浏览，部分页面按需登录），通过 `AUTH_MODE` 环境变量配置
- **Demo 登录** — 开发/演示构建一键 Mock 登录（`MOCK_AUTH=true`），无需真实后端
- **50+ 可复用 UI 组件** — 按钮、列表、状态组件、弹窗等，位于 `lib/shared/widgets/`
- **Talker 日志系统** — 结构化日志，Dio 集成，可选 Riverpod 观察器
- **flutter_screenutil** — 基于设计稿（375×812）的屏幕适配
- **l10n 国际化** — 基于 ARB 文件的 Flutter gen-l10n（`lib/l10n/`）

## 技术栈

| 库 | 版本约束 | 用途 |
|---|---------|------|
| Flutter SDK | ≥ 3.8 | UI 框架 |
| Dart SDK | ≥ 3.8.0 | 编程语言 |
| flutter_riverpod | ^3.0.0 | 状态管理 |
| riverpod_annotation / riverpod_generator | ^4.0.0 / ^4.0.0+1 | Provider 代码生成 |
| auto_route / auto_route_generator | ^11.1.0 / ^10.2.4 | 路由与代码生成 |
| dio | ^5.9.0 | 网络请求 |
| get_it / injectable | ^9.2.1 / ^2.5.1 | 服务定位与 DI 代码生成 |
| freezed / freezed_annotation | ^3.2.3 / ^3.1.0 | 不可变模型与联合类型 |
| json_serializable / json_annotation | ^6.11.1 / ^4.9.0 | JSON 序列化代码生成 |
| dartz | ^0.10.1 | Either 错误处理 |
| flutter_dotenv | ^6.0.0 | 环境变量 |
| hive / hive_flutter | ^2.2.3 / ^1.1.0 | 本地 NoSQL 存储 |
| shared_preferences | ^2.5.3 | 键值对偏好存储 |
| flutter_secure_storage | ^10.0.0 | 安全 Token 存储 |
| talker_flutter / talker_dio_logger / talker_riverpod_logger | ^5.x | 日志与集成 |
| flutter_screenutil | ^5.9.3 | 屏幕适配 |
| intl + flutter_localizations | SDK / ^0.20.2 | 国际化 |
| build_runner | ^2.5.4 | 代码生成编排 |

## 快速开始

1. **克隆** 此仓库（或作为 GitHub 模版使用），打开项目目录
2. **初始化** — 安装依赖并运行交互式配置脚本：
   ```bash
   flutter pub get
   dart run tool/setup.dart   # 可选：修改包名、组织名、显示名
   just gen                   # 或: dart run build_runner build --delete-conflicting-outputs
   ```
3. **运行** 应用（开发环境）：
   ```bash
   just dev
   ```
   或：`flutter run --dart-define=ENVIRONMENT=development`

## 项目结构

```text
lib/
├── core/                 # 应用级基础设施（不含业务逻辑）
│   ├── constants/        # 应用常量
│   ├── di/               # 依赖注入（GetIt + Injectable）
│   ├── env/              # 环境配置（flutter_dotenv）
│   ├── errors/           # 错误类型定义 + 全局错误处理
│   ├── extensions/       # Dart 扩展（Dartz 扩展等）
│   ├── initializers/     # 第三方 SDK 初始化
│   ├── l10n/             # 国际化逻辑（语言切换 Provider）
│   ├── logger/           # 日志系统（Talker）
│   ├── network/          # 网络层（ApiClient、拦截器、Token 管理）
│   ├── router/           # 路由配置（AutoRoute、守卫）
│   ├── storage/          # 存储服务（Hive、SharedPrefs、SecureStorage）
│   └── theme/            # 主题与设计系统
├── shared/               # 跨功能模块复用（组件、工具类、共享 API/模型）
│   ├── apis/             # 共享 API 定义
│   ├── cache/            # 缓存服务
│   ├── models/           # 共享数据模型（API 响应、分页等）
│   ├── services/         # 共享服务（AppInfoService 等）
│   ├── utils/            # 工具类
│   └── widgets/          # 通用 UI 组件（50+ 组件）
├── features/             # 功能切片（示例：auth、app shell、_example）
│   ├── <feature>/
│   │   ├── data/         # 数据源、Repository 实现、DTO/Model
│   │   ├── domain/       # Repository 接口、Entity（可选）
│   │   └── presentation/ # 页面、组件、Provider
│   └── ...
├── l10n/                 # ARB 翻译源文件
└── main.dart
```

### 内置示例

- `lib/features/auth/` — 认证功能：远程数据源、Repository、Riverpod Notifier
- `lib/features/_example/` — 列表/详情流程，带分页风格 Repository（Mock 数据）
- `lib/features/app/` — 应用壳层、启动页、引导页、设置页、开发工具路由

## 架构概览

- **Presentation 表现层** — 页面、组件和 Riverpod Provider/Notifier。通过 `getIt<YourRepository>()` 调用 Domain 层的 Repository 接口
- **Domain 领域层** — Repository 接口契约和可选的 Entity（当 API 数据结构不直接满足 UI 需求时）
- **Data 数据层** — 数据源（REST、本地）、DTO/Model、Repository 实现（通过 Injectable 注册）

**依赖方向：Presentation → Domain ← Data**

UI 层永远不依赖具体的 Repository 或 DataSource 实现类 — 仅依赖抽象接口和 shared/core 工具。

详见 [docs/architecture.zh-CN.md](docs/architecture.zh-CN.md)。

## 认证模式

模版内置两种可配置的认证模式，通过 `assets/env/.env*` 中的 `AUTH_MODE` 环境变量控制：

| 模式 | `AUTH_MODE` | 行为 |
|------|-------------|------|
| **强制登录** | `required`（默认） | 所有路由都需要登录。未认证用户启动后跳转到登录页 |
| **可选登录** | `optional` | 应用默认进入首页。仅 `AuthGuard.authRequiredRoutes` 中列出的路由（如个人中心）需要登录 |

### Demo 登录

当 `MOCK_AUTH=true`（`development` 环境默认开启）时，登录页会显示 **「Demo Login」** 按钮，使用 Mock Token 模拟认证，无需真实 API。适用于：

- 首次评估模版
- 无后端情况下的 UI 开发
- 自动化测试

在 staging / production 环境中将 `MOCK_AUTH=false` 以使用真实 API 认证。

## 常用命令

命令定义在 [`justfile`](justfile) 中。安装 [just](https://github.com/casey/just) 后使用。

| 命令 | 说明 |
|------|------|
| `just` | 列出所有可用命令（默认） |
| `just dev` | 以 `ENVIRONMENT=development` 运行 |
| `just staging` | 以 `ENVIRONMENT=staging` 运行 |
| `just prod-debug` | 以 `ENVIRONMENT=production` 调试运行 |
| `just release` | 以 `ENVIRONMENT=production` Release 模式运行 |
| `just android-build-debug` | 构建 Debug APK (arm64) |
| `just android-build-release` | 构建 Release APK (arm64) |
| `just ios-build` | 构建 iOS Release |
| `just gen` | 代码生成：`dart run build_runner build --delete-conflicting-outputs` |
| `just gen-watch` | 监听模式代码生成 |
| `just clean` | `flutter clean && flutter pub get` |
| `just reset` | 清理 + 代码生成 |
| `just analyze` | `flutter analyze --no-fatal-infos` |
| `just test` | `flutter test` |
| `just deps` | `flutter pub get` |

## 创建新功能模块

1. 创建 `lib/features/<name>/{data,domain,presentation}/` 及相应子目录
2. 在 `data/models/` 下添加 Freezed 数据模型，在 `domain/repositories/` 下定义 Repository 接口
3. 用 `@Singleton(as: YourRepository)` 或 `@Injectable()` 注解实现类，运行 `just gen`
4. 添加 `@RoutePage()` 页面并在 `lib/core/router/app_router.dart` 注册路由
5. 使用 `@riverpod` / `@Riverpod` 创建 Provider，通过 `getIt<YourRepository>()` 调用

详细教程：[docs/create_new_feature.zh-CN.md](docs/create_new_feature.zh-CN.md)

## 文档

| 文档 | 说明 |
|------|------|
| [docs/getting_started.zh-CN.md](docs/getting_started.zh-CN.md) | 前置条件、安装配置、代码生成、运行、环境切换 |
| [docs/architecture.zh-CN.md](docs/architecture.zh-CN.md) | 架构分层、依赖流向、Riverpod & Either |
| [docs/create_new_feature.zh-CN.md](docs/create_new_feature.zh-CN.md) | 端到端功能开发教程 |
| [docs/conventions.zh-CN.md](docs/conventions.zh-CN.md) | 命名规范、导入顺序、Freezed 模式、Provider 模式 |
| [docs/core_modules.zh-CN.md](docs/core_modules.zh-CN.md) | Core 层模块说明（网络、存储、路由等） |
| [docs/app_resources.zh-CN.md](docs/app_resources.zh-CN.md) | 启动图标 & 原生启动屏配置 |

## 开源协议

MIT
