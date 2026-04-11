# 应用资源 — 启动图标 & 原生启动屏

本文档介绍两个**代码生成工具**，它们从单一配置文件生成**平台原生**资源。它们不是运行时依赖，而是在开发期间修改项目文件，生成的资源提交到版本控制。

## flutter_launcher_icons（启动图标生成器）

> **作用**：从一张源图片自动生成各平台的应用启动图标（Android 自适应图标、iOS 图标集、Web favicon、macOS/Windows 图标）。

### 为什么需要它？

没有此工具，你需要手动创建并放置数十个不同尺寸的图标到 `android/app/src/main/res/mipmap-*`、`ios/Runner/Assets.xcassets/AppIcon.appiconset/` 等目录。此工具从一张高清 PNG 自动完成所有工作。

### 配置文件

配置文件位于项目根目录：**`flutter_launcher_icons.yaml`**

关键参数：

| 参数 | 说明 |
|------|------|
| `image_path` | 源图片路径（推荐：1024×1024 PNG，无透明通道） |
| `android` | 设为启动图标名称字符串（如 `'launcher_icon'`）或 `true` 以生成 Android 图标 |
| `min_sdk_android` | 最低 Android SDK 版本（默认 21） |
| `adaptive_icon_background` | Android 自适应图标的背景色或背景图（Android 8+） |
| `adaptive_icon_foreground` | 自适应图标的前景图 |
| `ios` | `true` 生成 iOS 图标 |
| `remove_alpha_ios` | `true` 移除 Alpha 通道（App Store 要求） |
| `web` / `macos` / `windows` | 各平台独立配置（见配置文件注释） |

### 使用方法

```bash
# 使用 justfile
just gen-icon

# 手动命令
flutter pub run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

### 生成产物

| 平台 | 输出 |
|------|------|
| Android | `android/app/src/main/res/mipmap-*/launcher_icon.png` + 自适应图标 XML |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/`（所有必需尺寸） |
| Web | `web/icons/` + 更新 `web/manifest.json` |
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` |

### 工作流程

1. 将源图标放置到 `assets/icon/app_icon.png`（1024×1024 PNG）
2. 按需编辑 `flutter_launcher_icons.yaml`（如启用自适应图标、Web、macOS 等）
3. 运行 `just gen-icon`
4. 构建并运行应用，验证生成的图标
5. 提交生成的文件

### 注意事项

- **Android 自适应图标**：提供独立的前景/背景图可在 Android 8+ 上获得现代化效果。前景图应有透明留白（安全区域为画布的 66%）
- **iOS**：App Store 要求图标无 Alpha 通道 — 保持 `remove_alpha_ios: true`
- **重新运行**：工具会覆盖之前的输出，可以自由迭代

---

## flutter_native_splash（原生启动屏生成器）

> **作用**：为 Android、iOS 和 Web 生成原生启动屏资源，在 Flutter 渲染第一帧**之前**显示。替代默认的白屏为你的品牌形象/颜色。

### 为什么需要它？

Flutter 应用有一个短暂的"冷启动"阶段，此时原生平台代码在加载 Dart VM 和框架。在此期间，系统会显示一个原生启动屏。如果不自定义，它就是一个空白白屏。此工具让你控制用户在这段时间看到的内容。

### 在模版中的工作方式

模版使用 **preserve + remove** 模式：

```text
应用启动
  │
  ▼
┌──────────────────────────────┐
│  原生启动屏（由                  │ ← 由 flutter_native_splash.yaml 控制
│  flutter_native_splash 生成）   │
└──────────┬───────────────────┘
           │  FlutterNativeSplash.preserve(widgetsBinding)
           │  （在 AppInitializer.initialize 中调用）
           ▼
┌──────────────────────────────┐
│  应用初始化                      │ ← 加载环境配置、日志、DI 等
│  （初始化期间保持原生启动屏可见）    │
└──────────┬───────────────────┘
           │  FlutterNativeSplash.remove()
           │  （在 SplashPage 初始化完成后调用）
           ▼
┌──────────────────────────────┐
│  Flutter SplashPage            │ ← Dart 渲染的启动/过渡页
│  → 导航到登录页或首页             │
└──────────────────────────────┘
```

**代码位置：**

- `lib/core/initializers/app_initializer.dart` — 调用 `FlutterNativeSplash.preserve()` 在异步初始化期间保持原生启动屏可见
- `lib/features/app/presentation/pages/splash_page/splash_page.dart` — 初始化完成后调用 `FlutterNativeSplash.remove()`，然后导航

### 配置文件

配置文件位于项目根目录：**`flutter_native_splash.yaml`**

关键参数：

| 参数 | 说明 |
|------|------|
| `color` | 纯色背景（十六进制，如 `'#ffffff'`） |
| `background_image` | 替代方案：背景 PNG（拉伸填充） |
| `image` | 可选：居中 Logo 图片（PNG，按 4x 像素密度设计） |
| `branding` | 可选：屏幕底部品牌图片 |
| `color_dark` / `image_dark` | 暗黑模式变体 |
| `android_12` | Android 12+ 独立配置（使用不同的启动屏 API） |
| `android` / `ios` / `web` | 设为 `false` 可跳过该平台 |
| `fullscreen` | `true` 隐藏通知栏 |

### 使用方法

```bash
# 生成启动屏
just gen-splash

# 手动命令
dart run flutter_native_splash:create --path=flutter_native_splash.yaml

# 恢复 Flutter 默认白屏（移除自定义）
dart run flutter_native_splash:remove
```

### 生成产物

| 平台 | 输出 |
|------|------|
| Android (<12) | `android/app/src/main/res/drawable/` + `values/` + `styles.xml` 修改 |
| Android (12+) | `android/app/src/main/res/values-v31/` + `drawable-v31/` |
| iOS | `ios/Runner/Base.lproj/LaunchScreen.storyboard` + 图片资源 |
| Web | `web/splash/` 资源 + `web/index.html` 修改 |

### 工作流程

1. 准备启动屏素材：
   - 背景：纯色 OR 全屏 PNG
   - Logo（可选）：居中 PNG，按 4x 像素密度设计
   - Android 12 图标（可选）：960×960 或 1152×1152 PNG
2. 编辑 `flutter_native_splash.yaml`
3. 运行 `just gen-splash`
4. 在真机上测试（模拟器可能跳过启动屏）
5. 提交生成的文件

### 注意事项

- **Android 12+ 机制不同**：使用系统级启动屏 API，居中图标会被裁剪为圆形。需在 `android_12` 段落单独配置
- **preserve/remove 模式**：务必在 `main()` 早期调用 `FlutterNativeSplash.preserve()`，在应用准备好后调用 `FlutterNativeSplash.remove()`。模版已自动处理
- **暗黑模式**：提供 `_dark` 变体以在暗黑模式设备上获得良好体验
- **重新运行**：生成的文件每次都会被覆盖，可以自由迭代

---

## 快速参考

| 任务 | 命令 |
|------|------|
| 生成启动图标 | `just gen-icon` |
| 生成原生启动屏 | `just gen-splash` |
| 移除启动屏自定义 | `dart run flutter_native_splash:remove` |
| 重新生成所有代码（Riverpod、Freezed 等） | `just gen` |

### 资源目录结构

```text
assets/
├── env/                  # 环境文件（.env.*）
├── icon/                 # 启动图标源文件
│   └── app_icon.png      # 1024x1024 源图标
└── splash/               # 启动屏源文件
    └── splash_logo.png   # 可选的居中 Logo
```
