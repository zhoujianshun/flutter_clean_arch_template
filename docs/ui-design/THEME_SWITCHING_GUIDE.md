# 主题切换功能指南

本指南说明项目当前主题切换能力、实际接入方式，以及和新主题系统（`AppColors` / `AppDarkColors` / `AppAdaptiveColors`）的配合方式。

## 1. 当前状态（请先阅读）

项目已支持三种主题模式：

- `ThemeMode.light`
- `ThemeMode.dark`
- `ThemeMode.system`

当前实现特点：

1. `MaterialApp.router` 已接入 `theme` / `darkTheme` / `themeMode`，切换实时生效。
2. `setThemeMode()` 和 `toggleThemeMode()` 会保存到 `StorageService`。
3. `loadThemeMode()` 已实现，但**当前未在启动流程自动调用**。
4. `AppThemeMode.build()` 当前默认返回 `ThemeMode.light`。

这意味着：应用每次冷启动默认浅色，除非你手动在启动时调用 `loadThemeMode()` 恢复上次选择。

## 2. 核心组件

- 状态管理：`lib/core/theme/theme_mode_provider.dart`
- 主题定义：`lib/core/theme/app_theme.dart`
- 切换组件：`lib/shared/widgets/theme_switcher.dart`

`ThemeSwitcher` 提供 4 种样式：

- `ThemeSwitcherStyle.listTile`（默认，设置页推荐）
- `ThemeSwitcherStyle.iconButton`（工具栏推荐）
- `ThemeSwitcherStyle.segmentedButton`
- `ThemeSwitcherStyle.dropdown`

快捷组件：

- `ThemeToggleFab`
- `AppBarThemeButton`

## 3. 基础接入

在根应用中监听 `appThemeModeProvider`：

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // ...
    );
  }
}
```

## 4. 添加切换 UI

### 4.1 列表项（设置页）

```dart
const ThemeSwitcher(
  style: ThemeSwitcherStyle.listTile,
)
```

### 4.2 图标按钮（AppBar）

```dart
const ThemeSwitcher(
  style: ThemeSwitcherStyle.iconButton,
  showLabel: false,
)
```

### 4.3 分段按钮

```dart
const ThemeSwitcher(
  style: ThemeSwitcherStyle.segmentedButton,
)
```

### 4.4 下拉菜单

```dart
const ThemeSwitcher(
  style: ThemeSwitcherStyle.dropdown,
)
```

## 5. 程序化控制

```dart
class ThemeActions extends ConsumerWidget {
  const ThemeActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appThemeModeProvider.notifier);

    return Row(
      children: [
        ElevatedButton(
          onPressed: () => notifier.toggleThemeMode(),
          child: const Text('循环切换'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => notifier.setThemeMode(ThemeMode.dark),
          child: const Text('切到深色'),
        ),
      ],
    );
  }
}
```

## 6. 启动时恢复上次主题（可选但推荐）

如果希望恢复用户上次选择，请在应用启动后调用一次 `loadThemeMode()`。

可参考以下包装组件：

```dart
class ThemeModeBootstrapper extends ConsumerStatefulWidget {
  const ThemeModeBootstrapper({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ThemeModeBootstrapper> createState() =>
      _ThemeModeBootstrapperState();
}

class _ThemeModeBootstrapperState
    extends ConsumerState<ThemeModeBootstrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(appThemeModeProvider.notifier).loadThemeMode();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

然后在根节点包裹：

```dart
ThemeModeBootstrapper(
  child: MaterialApp.router(
    // ...
  ),
)
```

## 7. 与颜色系统的配合

主题切换本质上只切换 `ThemeMode`，颜色渲染依赖 `AppTheme` 与 token 系统：

- `AppTheme`：负责浅/深 `ThemeData` 与 `ColorScheme` 映射。
- `AppAdaptiveColors`：负责业务组件颜色自动适配。

建议：

1. Material 组件优先使用 `Theme.of(context).colorScheme`。
2. 自定义组件优先使用 `AppAdaptiveColors.*(context)`。
3. 避免在业务层直接引用 `AppDarkColors`。

## 8. 测试与验证

当前仓库已有主题核心回归测试：

```bash
flutter test test/core/theme/app_theme_test.dart
```

可选静态检查：

```bash
dart analyze lib/core/theme/app_theme.dart lib/core/theme/theme_mode_provider.dart
```

## 9. 常见问题

### Q1：为什么切换后重启又变回浅色？

因为当前 `build()` 默认返回 `ThemeMode.light`，且启动流程未自动调用 `loadThemeMode()`。  
按第 6 节接入后可恢复持久化主题。

### Q2：点击切换按钮无效怎么办？

请确认 `MaterialApp` 的 `themeMode` 来自：

```dart
final themeMode = ref.watch(appThemeModeProvider);
```

### Q3：深色模式下自定义组件颜色不对

请检查是否使用了硬编码色值。  
建议改为 `AppAdaptiveColors` 或 `colorScheme` 语义色。

---

补充说明：若后续你调整了 `theme_mode_provider.dart` 的默认策略（例如默认改为 `ThemeMode.system` 或在 `build()` 中自动恢复），请同步更新本指南的“当前状态”章节。
