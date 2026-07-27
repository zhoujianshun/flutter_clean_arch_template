# 自定义主题系统使用指南

本指南用于说明项目当前主题系统的真实结构和推荐用法。  
内容已对齐 `lib/core/theme/app_theme.dart` 的最新实现（含 `AppDarkColors` 和 `ColorScheme` 统一映射）。

## 1. 主题架构

当前主题由 5 层组成：

1. `AppColors`：浅色主题设计 token（静态常量）。
2. `AppDarkColors`：深色主题设计 token（静态常量）。
3. `AppAdaptiveColors`：运行时根据明暗模式自动选择浅/深 token。
4. `AppTheme`：`ThemeData` + `ColorScheme` 的统一配置入口。
5. `AppTextStyles`、`AppSpacing`、`AppBorderRadius`：文字/间距/圆角规范。

推荐理解方式：

- `AppColors` / `AppDarkColors` 负责“定义颜色”。
- `AppAdaptiveColors` 负责“按模式路由颜色”。
- `AppTheme` 负责“把 token 接入 Flutter Material 主题系统”。

## 2. 颜色系统

## 2.1 浅色 token：`AppColors`

可用颜色分组如下：

- 品牌色：`primary`、`primary50`、`primary500`、`primary700`
- 功能色：`success50/500/700`、`warning50/500/700`、`error50/500/700`、`info50/500/700`
- 中性色：`neutral50/100/150/200/300/400/500/600/650/700/750/800/900`
- 文本色：`textPrimary`、`textSecondary`、`textHint`、`textDisabled`
- 背景色：`backgroundPrimary`、`backgroundSecondary`、`backgroundTertiary`、`surface`
- 边框分割：`border`、`divider`

## 2.2 深色 token：`AppDarkColors`

可用颜色分组如下：

- 品牌色：`primary`、`primary50`、`primary500`、`primary700`
- 功能色：`success50/500`、`warning50/500`、`error50/500/700`
- 中性色：`neutral50/100/150/200/300/400/500/600/650/700/750/800/900`
- 文本色：`textPrimary`、`textSecondary`、`textHint`、`textDisabled`
- 背景色：`backgroundPrimary`、`backgroundSecondary`、`surface`
- 边框分割：`border`、`divider`

## 2.3 自适应颜色：`AppAdaptiveColors`

在业务 UI 中，优先使用 `AppAdaptiveColors`，避免手写 `Theme.of(context).brightness`。

当前可用接口：

- 品牌：`primary`、`primary50`、`primary500`、`primary700`
- 功能：`success50`、`success500`、`warning50`、`warning500`、`error50`、`error500`、`error700`
- 中性：`neutral50/100/150/200/300/400/500/600/650/700/750/800/900`
- 文本：`textPrimary`、`textSecondary`、`textHint`、`textDisabled`
- 背景：`backgroundPrimary`、`backgroundSecondary`、`surface`
- 边框分割：`border`、`divider`

> 注意：当前没有 `onSurface()`、`healthGood()`、`emergency()` 等方法，文档和代码请统一使用现有接口。

## 3. `ColorScheme` 统一映射（重要）

`AppTheme` 内维护了 `_lightColorScheme` 和 `_darkColorScheme`，都从 token 映射得到。  
核心映射规则（浅色与深色都一致）：

- `primary` -> `primary`
- `primaryContainer` -> `primary50`
- `onPrimaryContainer` -> `primary700`
- `surface` -> `surface`
- `onSurface` -> `textPrimary`
- `error` -> `error500`
- `outline` -> `border`

这样做的好处：

- Material 组件（按钮、对话框、导航栏）和自定义组件共享一套语义颜色。
- 后续改 token 时，`ThemeData` 和业务 UI 不会出现色彩漂移。

## 4. `ThemeData` 关键约束

- 项目启用 `useMaterial3: true`。
- 已同时维护浅色/深色的 `appBar/card/input/button/divider/bottomNavigationBar` 子主题。
- `ElevatedButton` 全局最小尺寸为 `Size(0, 48.h)`，只约束高度，不强制全宽。

全宽按钮请在业务层显式设置：

```dart
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {},
    child: const Text('提交'),
  ),
)
```

在横向布局里建议用 `Expanded`/`Flexible` 控制宽度，而不是依赖全局按钮样式。

## 5. 字体系统：`AppTextStyles`

当前可用样式：

- 标题：`h1`、`h2`、`h3`、`h4`、`h5`、`h6`
- 正文：`bodyLarge`、`bodyMedium`、`bodySmall`、`bodyXSmall`
- 标签：`labelLarge`、`labelMedium`、`labelSmall`
- 其他：`caption`、`overline`、`elderlyBodyLarge`

字体族常量：

- `fontFamilyMedium`
- `fontFamilyRegular`

这两个值目前为 `null`，表示默认使用系统字体。若要接入自定义字体，请先在 `pubspec.yaml` 配置 `fonts` 再赋值。

## 6. 间距与圆角

`AppSpacing`：

- `xs=ResponsiveTokens.size(4, medium: 4, expanded: 4)`
- `sm=ResponsiveTokens.size(8, medium: 8, expanded: 8)`
- `md=ResponsiveTokens.size(12, medium: 12, expanded: 12)`
- `lg=ResponsiveTokens.size(16, medium: 16, expanded: 16)`
- `xl=ResponsiveTokens.size(24, medium: 24, expanded: 24)`
- `xxl=ResponsiveTokens.size(32, medium: 32, expanded: 32)`

`AppBorderRadius`：

- `xs=BorderRadius.circular(ResponsiveTokens.size(4, ...))`
- `sm=BorderRadius.circular(ResponsiveTokens.size(8, ...))`
- `md=BorderRadius.circular(ResponsiveTokens.size(12, ...))`
- `lg=BorderRadius.circular(ResponsiveTokens.size(16, ...))`
- `xl=BorderRadius.circular(ResponsiveTokens.size(24, ...))`
- `full=BorderRadius.circular(ResponsiveTokens.size(999, ...))`

## 7. 推荐用法示例

### 7.1 自适应卡片

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppAdaptiveColors.surface(context),
    borderRadius: AppBorderRadius.md,
    border: Border.all(color: AppAdaptiveColors.border(context)),
  ),
  child: Text(
    '主题自适应内容',
    style: AppTextStyles.bodyMedium.copyWith(
      color: AppAdaptiveColors.textPrimary(context),
    ),
  ),
)
```

### 7.2 成功状态提示

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppAdaptiveColors.success50(context),
    borderRadius: AppBorderRadius.sm,
    border: Border.all(color: AppAdaptiveColors.success500(context)),
  ),
  child: Row(
    children: [
      Icon(Icons.check_circle, color: AppAdaptiveColors.success500(context)),
      SizedBox(width: AppSpacing.sm),
      Text(
        '操作成功',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppAdaptiveColors.textPrimary(context),
        ),
      ),
    ],
  ),
)
```

## 8. 最佳实践

1. **Material 组件优先走 `Theme.of(context).colorScheme`**，保证组件语义一致。
2. **自定义业务 UI 优先走 `AppAdaptiveColors`**，避免深浅色分支散落。
3. **避免在业务代码直接引用 `AppDarkColors`**，暗色 token 应由适配层路由。
4. **避免硬编码颜色值**，新增颜色先补 token 再使用。
5. **新增 token 时同时补文档与测试**，防止后续回归。

## 9. 验证命令

```bash
# 主题配置回归测试
flutter test test/core/theme/app_theme_test.dart

# 静态检查（按需）
dart analyze lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
```

## 10. 常见问题

### Q1：为什么不直接在 Widget 里写 `AppDarkColors`？

A：这样会把“暗色判断逻辑”扩散到业务层，后续很难维护。  
推荐统一使用 `AppAdaptiveColors`。

### Q2：为什么全局按钮不再默认全宽？

A：全局 `double.infinity` 在 `Row`/横向布局会引发布局风险。  
当前仅统一最小高度；是否全宽由具体页面决定，更安全也更灵活。
