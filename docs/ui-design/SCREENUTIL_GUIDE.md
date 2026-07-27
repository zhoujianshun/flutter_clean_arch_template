# Flutter ScreenUtil 响应式设计指南

本指南用于说明项目里 `flutter_screenutil` 的实际用法，以及它与主题系统（`AppTheme` / `AppTextStyles` / `AppSpacing` / `AppBorderRadius`）的配合方式。

## 1. 当前配置（与代码一致）

项目在 `main.dart` 中使用：

```dart
ScreenUtilInit(
  designSize: const Size(375, 812),
  minTextAdapt: true,
  splitScreenMode: true,
  useInheritedMediaQuery: true,
  builder: (context, child) {
    return MaterialApp.router(
      // ...
    );
  },
)
```

说明：

- `375x812` 是当前默认设计稿尺寸。
- `minTextAdapt: true` 有助于小屏设备文字可读性。
- `splitScreenMode: true` 支持分屏场景。

## 2. 响应式单位速查

```dart
100.w // 宽度适配
100.h // 高度适配
16.sp // 字号适配
12.r  // 圆角适配（数值）
```

屏幕信息：

```dart
final width = 1.sw;
final height = 1.sh;
final statusBar = ScreenUtil().statusBarHeight;
final bottomSafe = ScreenUtil().bottomBarHeight;
```

## 3. 与主题系统集成

项目主题样式已内置 ScreenUtil，建议优先复用主题 token：

- 字体：`AppTextStyles.*`
- 间距：`AppSpacing.*`
- 圆角：`AppBorderRadius.*`
- 颜色：`AppAdaptiveColors.*(context)` 或 `Theme.of(context).colorScheme`

关键点：

1. `AppSpacing` 当前值：`xs=4.w`、`sm=8.w`、`md=12.w`、`lg=16.w`、`xl=24.w`、`xxl=32.w`。
2. `AppBorderRadius` 返回的是 `BorderRadius`，可直接赋给 `BoxDecoration.borderRadius`。
3. 避免写成 `BorderRadius.circular(AppBorderRadius.md)`（类型不匹配）。

## 4. ResponsiveUtils 工具类

路径：`lib/shared/utils/responsive_utils.dart`

```dart
import 'package:flutter_clean_arch_template/shared/utils/responsive_utils.dart';
```

常用能力：

- 设备判断：`isMobile/isTablet/isDesktop`
- 自适应值：`responsiveValue<T>()`
- 布局辅助：`getColumns()`、`getGridColumns()`、`getHorizontalPadding()`
- 适老化：`getElderlyFontScale()`、`getElderlyButtonHeight()`、`getElderlyTouchTarget()`
- 组件：`ResponsiveBuilder`、`ResponsiveLayoutBuilder`、`ElderlyResponsiveWidget`

## 5. 使用示例

### 5.1 基础卡片

```dart
class MyCard extends StatelessWidget {
  const MyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,
      padding: EdgeInsets.all(AppSpacing.md),
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppAdaptiveColors.surface(context),
        borderRadius: AppBorderRadius.md,
        border: Border.all(color: AppAdaptiveColors.border(context)),
      ),
      child: Text(
        '响应式卡片',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppAdaptiveColors.textPrimary(context),
        ),
      ),
    );
  }
}
```

### 5.2 按钮（支持适老化高度）

```dart
class ResponsiveButton extends StatelessWidget {
  const ResponsiveButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isElderly = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isElderly;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isElderly ? ResponsiveUtils.getElderlyButtonHeight(context) : 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          textStyle: (isElderly ? AppTextStyles.bodyLarge : AppTextStyles.labelLarge).copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.md),
        ),
        child: Text(text),
      ),
    );
  }
}
```

### 5.3 列表头像色块

```dart
Container(
  width: 48.w,
  height: 48.w,
  decoration: BoxDecoration(
    color: AppAdaptiveColors.primary50(context),
    borderRadius: AppBorderRadius.sm,
  ),
  child: Icon(
    Icons.person,
    size: ResponsiveUtils.getIconSize(context),
  ),
)
```

### 5.4 适老化页面包装

```dart
class ElderlyFriendlyPage extends StatelessWidget {
  const ElderlyFriendlyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ElderlyResponsiveWidget(
      fontScale: 1.3,
      enableLargeTouch: true,
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text('适老化标题', style: AppTextStyles.h3),
              SizedBox(height: AppSpacing.xl),
              Text(
                '较大正文',
                style: AppTextStyles.elderlyBodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 6. 最佳实践

1. **优先 token**：间距/字体/圆角尽量复用 `AppSpacing`、`AppTextStyles`、`AppBorderRadius`。
2. **减少魔法数字**：只在特殊布局场景写裸值，并补注释。
3. **按语义取色**：业务组件优先用 `AppAdaptiveColors`，Material 组件优先用 `colorScheme`。
4. **控制全宽按钮**：全宽由 `SizedBox(width: double.infinity)` 决定，不依赖全局主题强制宽度。
5. **兼顾平板**：复杂页面建议配合 `ResponsiveBuilder` 提供手机/平板布局。

## 7. 常见问题

### Q1：为什么样式在某些页面看起来没适配？

A：确认页面运行在 `ScreenUtilInit` 之下，且没有混用大量固定像素值。

### Q2：为什么圆角写法报错？

A：`AppBorderRadius.md` 已经是 `BorderRadius`，请直接赋值，不要再 `BorderRadius.circular(...)`。

### Q3：深色模式下颜色不一致？

A：请使用 `AppAdaptiveColors.*(context)` 或 `Theme.of(context).colorScheme`，避免硬编码颜色。

## 8. 参考文档

- `ui-design/CUSTOM_THEME_GUIDE.md`
- `ui-design/THEME_SWITCHING_GUIDE.md`
- `responsive/SCREENUTIL_GUIDE.md`（平板适配专项）
