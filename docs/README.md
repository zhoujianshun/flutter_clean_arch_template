# 文档中心 / Documentation Hub

本目录包含模板项目的完整技术文档，分为两大类：**核心文档**（快速上手必读）和**深入指南**（按专题分类的进阶参考）。

---

## 核心文档（Quick Start）

| 文档 | 说明 |
|------|------|
| [getting_started.md](getting_started.md) / [中文](getting_started.zh-CN.md) | 前置条件、安装配置、代码生成、运行、环境切换 |
| [architecture.md](architecture.md) / [中文](architecture.zh-CN.md) | 架构分层、依赖流向、Riverpod & Either |
| [create_new_feature.md](create_new_feature.md) / [中文](create_new_feature.zh-CN.md) | 端到端功能开发教程 |
| [conventions.md](conventions.md) / [中文](conventions.zh-CN.md) | 命名规范、导入顺序、Freezed 模式、Provider 模式 |
| [core_modules.md](core_modules.md) / [中文](core_modules.zh-CN.md) | Core 层模块说明（网络、存储、路由等） |
| [app_resources.md](app_resources.md) / [中文](app_resources.zh-CN.md) | 启动图标 & 原生启动屏配置 |

---

## 深入指南（Deep Dive Guides）

### 架构设计 (`architecture/`)

| 文档 | 主题 |
|------|------|
| [AUTHENTICATION_SYSTEM_V2.md](architecture/AUTHENTICATION_SYSTEM_V2.md) | 认证系统架构设计（Token 管理、网络错误联动） |
| [DARTZ_GUIDE.md](architecture/DARTZ_GUIDE.md) | Dartz Either 概念与用法入门 |
| [DARTZ_BEST_PRACTICES.md](architecture/DARTZ_BEST_PRACTICES.md) | Either/Failure 最佳实践 |
| [DARTZ_RIVERPOD_INTEGRATION.md](architecture/DARTZ_RIVERPOD_INTEGRATION.md) | Dartz + Riverpod 集成模式 |
| [DEPENDENCY_INJECTION_COMPLETE_GUIDE.md](architecture/DEPENDENCY_INJECTION_COMPLETE_GUIDE.md) | GetIt + Injectable 依赖注入完整指南 |
| [GET_IT_VS_RIVERPOD_COMPARISON.md](architecture/GET_IT_VS_RIVERPOD_COMPARISON.md) | GetIt vs Riverpod 对比分析 |
| [FREEZED_MIGRATION_GUIDE.md](architecture/FREEZED_MIGRATION_GUIDE.md) | Equatable → Freezed 迁移指南 |
| [FREEZED_SEALED_VS_ABSTRACT.md](architecture/FREEZED_SEALED_VS_ABSTRACT.md) | Freezed 3.0 sealed vs abstract 规则 |
| [NETWORK_ERROR_NOTIFICATION_SYSTEM.md](architecture/NETWORK_ERROR_NOTIFICATION_SYSTEM.md) | 网络错误通知系统设计 |
| [NETWORK_ERROR_QUICK_REFERENCE.md](architecture/NETWORK_ERROR_QUICK_REFERENCE.md) | 网络错误处理快速参考 |

### 路由导航 (`architecture/route/`)

| 文档 | 主题 |
|------|------|
| [ROUTING_SYSTEM_GUIDE.md](architecture/route/ROUTING_SYSTEM_GUIDE.md) | AutoRoute 路由系统使用指南 |
| [debouncer-guard.md](architecture/route/debouncer-guard.md) | 路由防抖守卫设计与实现 |

### 状态管理 (`state-management/`)

| 文档 | 主题 |
|------|------|
| [RIVERPOD_COMPLETE_GUIDE.md](state-management/RIVERPOD_COMPLETE_GUIDE.md) | Riverpod 完整使用指南 |
| [RIVERPOD_3_MIGRATION_GUIDE.md](state-management/RIVERPOD_3_MIGRATION_GUIDE.md) | Riverpod 2 → 3 迁移指南 |
| [PROVIDER_ORGANIZATION_GUIDE.md](state-management/PROVIDER_ORGANIZATION_GUIDE.md) | Provider 分层组织指南 |

### 日志系统 (`logging/`)

| 文档 | 主题 |
|------|------|
| [LOGGING_SYSTEM_GUIDE.md](logging/LOGGING_SYSTEM_GUIDE.md) | 日志系统完整指南（Talker 体系） |
| [TALKER_INTEGRATION.md](logging/TALKER_INTEGRATION.md) | Talker 集成步骤 |
| [PERFORMANCE_MONITORING_GUIDE.md](logging/PERFORMANCE_MONITORING_GUIDE.md) | 性能监控与计时模式 |

### 错误监控 (`monitoring/`)

| 文档 | 主题 |
|------|------|
| [GLOBAL_ERROR_HANDLING_GUIDE.md](monitoring/GLOBAL_ERROR_HANDLING_GUIDE.md) | 全局错误处理指南 |
| [PLATFORM_CHANNEL_ERROR_HANDLING.md](monitoring/PLATFORM_CHANNEL_ERROR_HANDLING.md) | Platform Channel 错误处理 |
| [FIREBASE_VS_SENTRY_COMPARISON.md](monitoring/FIREBASE_VS_SENTRY_COMPARISON.md) | Firebase Crashlytics vs Sentry 对比 |

### UI 设计 (`ui-design/`)

| 文档 | 主题 |
|------|------|
| [SCREENUTIL_GUIDE.md](ui-design/SCREENUTIL_GUIDE.md) | ScreenUtil 屏幕适配指南 |
| [CUSTOM_THEME_GUIDE.md](ui-design/CUSTOM_THEME_GUIDE.md) | 自定义主题设计指南 |
| [THEME_SWITCHING_GUIDE.md](ui-design/THEME_SWITCHING_GUIDE.md) | 主题切换实现指南 |

### 权限管理 (`permission/`)

| 文档 | 主题 |
|------|------|
| [FLUTTER_PERMISSION_MANAGEMENT_GUIDE.md](permission/FLUTTER_PERMISSION_MANAGEMENT_GUIDE.md) | Flutter 权限管理完整指南 |
| [PERMISSION_TROUBLESHOOTING.md](permission/PERMISSION_TROUBLESHOOTING.md) | 权限问题排错手册 |

### 开发工具 (`tools-config/`)

| 文档 | 主题 |
|------|------|
| [DEV_TOOLS_GUIDE.md](tools-config/DEV_TOOLS_GUIDE.md) | 开发工具链指南（Makefile / Just） |
| [ENV_CONFIG_GUIDE.md](tools-config/ENV_CONFIG_GUIDE.md) | 多环境配置指南（flutter_dotenv） |
| [IOS_INFO_PLIST_CONFIG.md](tools-config/IOS_INFO_PLIST_CONFIG.md) | iOS Info.plist 配置说明 |
| [PGYER_INTEGRATION_GUIDE.md](tools-config/PGYER_INTEGRATION_GUIDE.md) | 蒲公英内测分发集成（可选） |

### 开发流程 (`development/`)

| 文档 | 主题 |
|------|------|
| [CI_CD_SETUP_GUIDE.md](development/CI_CD_SETUP_GUIDE.md) | CI/CD 配置指南（GitHub Actions） |
| [DEVELOPMENT_GUIDE.md](development/DEVELOPMENT_GUIDE.md) | 开发规范与流程指南 |

### 统一 API 响应 (`features/`)

| 文档 | 主题 |
|------|------|
| [UNIFIED_API_RESPONSE_GUIDE.md](features/UNIFIED_API_RESPONSE_GUIDE.md) | 统一 API 响应处理模式 |

### 应用上架 (`app-store-release/`)

| 文档 | 主题 |
|------|------|
| [README.md](app-store-release/README.md) | 上架流程总览与索引 |
| [01 准备总览](app-store-release/01-preparation-overview.md) | 上架前准备清单与时间线 |
| [02 企业资质](app-store-release/02-enterprise-qualification.md) | 开发者账号与企业资质 |
| [03 应用素材](app-store-release/03-app-materials-guide.md) | 图标、截图、视频规范 |
| [04 文案撰写](app-store-release/04-content-writing-guide.md) | 应用描述、隐私政策、更新日志 |
| [05 技术准备](app-store-release/05-technical-preparation.md) | 构建、签名、版本号管理 |
| [06 Android 上架](app-store-release/06-android-release-guide.md) | 国内 Android 应用市场发布流程 |
| [07 iOS 上架](app-store-release/07-ios-release-guide.md) | App Store 发布流程 |
| [08 审核清单](app-store-release/08-review-checklist.md) | 提审前检查清单 |
| [09 时间规划](app-store-release/09-time-planning.md) | 三周上架排期模板 |
| [10 常见问题](app-store-release/10-faq-and-tips.md) | FAQ 与实用技巧 |

---

## 文档统计

- **核心文档**: 6 篇（中英双语共 12 个文件）
- **深入指南**: 36 篇
- **总计**: 48 篇文档

> 建议阅读顺序：核心文档 → 架构设计 → 状态管理 → 日志/监控 → 其余按需查阅
