# Flutter ScreenUtil 响应式设计指南

本指南介绍如何在项目中使用 `flutter_screenutil` 实现响应式设计，以及它与项目自定义响应式工具的配合方式。

## 概述

`flutter_screenutil` 负责**微观尺寸**的适配（间距、字体、圆角等），而**宏观布局**（分栏、导航切换）由 `ResponsiveUtils` + `AdaptiveBuilder` 体系处理。两者各司其职：

| 职责 | 工具 | 示例 |
|------|------|------|
| 间距 / 字体 / 圆角缩放 | ScreenUtil `.w` `.sp` `.r` | `padding: EdgeInsets.all(16.w)` |
| 大屏缩放上限 | `ResponsiveUtils.aw()` | `SizedBox(width: ResponsiveUtils.aw(16))` |
| 平板设计稿缩放 | `ResponsiveUtils.tw()` | `padding: EdgeInsets.all(ResponsiveUtils.tw(20))` |
| 布局结构切换 | `AdaptiveBuilder` / `AdaptiveLayoutBuilder` | 手机单列 → 平板分栏 |

## 初始化配置

### 依赖

```yaml
dependencies:
  flutter_screenutil: ^5.9.3
```

### ScreenUtilInit 配置

项目在 `lib/main.dart` 中配置 ScreenUtil：

```dart
import 'dart:math';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_utils.dart';

return ScreenUtilInit(
  // 使用手机端设计稿尺寸（375 × 812）
  designSize: const Size(
    ResponsiveUtils.phoneDesignWidth,   // 375
    ResponsiveUtils.phoneDesignHeight,  // 812
  ),
  minTextAdapt: true,
  splitScreenMode: true,
  useInheritedMediaQuery: true,
  fontSizeResolver: (fontSize, instance) {
    // 平板/桌面端（>= 600dp）：不缩放字体，直接用 dp 值
    if (instance.screenWidth >= ResponsiveUtils.compactBreakpoint) {
      return fontSize.toDouble();
    }
    // 手机端：宽高混合缩放，避免极端屏幕比例下字体失真
    final scaleW = instance.screenWidth / ResponsiveUtils.phoneDesignWidth;
    final scaleH = instance.screenHeight / ResponsiveUtils.phoneDesignHeight;
    final scale = min(scaleW, scaleH) * 0.85 + max(scaleW, scaleH) * 0.15;
    return fontSize * scale;
  },
  builder: (context, child) {
    return MaterialApp.router(/* ... */);
  },
);
```

### 关键设计决策

1. **designSize 使用手机稿尺寸**：ScreenUtil 的 `.w`/`.sp` 在手机端正常缩放
2. **平板端字体不缩放**：`fontSizeResolver` 在屏幕宽度 >= 600dp 时直接返回原始 dp 值，避免字体在大屏上过大
3. **手机端混合缩放**：85% 取较小缩放比 + 15% 取较大缩放比，兼顾极端屏幕比例

## 响应式单位

### 基础单位

```dart
16.w    // 宽度适配：基于设计稿宽度（375）缩放
16.h    // 高度适配：基于设计稿高度（812）缩放
16.sp   // 字体适配：经 fontSizeResolver 处理（平板端不缩放）
8.r     // 圆角适配：取 w/h 中较小的缩放比
```

### 屏幕信息

```dart
1.sw                              // 屏幕宽度
1.sh                              // 屏幕高度
ScreenUtil().statusBarHeight      // 状态栏高度
ScreenUtil().bottomBarHeight      // 底部安全区域高度
```

## ScreenUtil 与 ResponsiveUtils 的配合

### 手机端：正常使用 `.w` / `.sp`

```dart
// 手机端页面中，直接用 ScreenUtil 扩展
Container(
  padding: EdgeInsets.all(16.w),
  child: Text('标题', style: TextStyle(fontSize: 18.sp)),
)
```

### 大屏安全缩放：`aw()` 替代 `.w`

当手机端代码也会在大屏上运行时，`.w` 值可能过大。用 `aw()` 限制上限：

```dart
// aw() 在手机端行为与 .w 一致
// 在大屏端 clamp 缩放比至 1.2，防止间距/尺寸过大
Container(
  padding: EdgeInsets.all(ResponsiveUtils.aw(16)),  // 大屏最大 16 * 1.2 = 19.2
  margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.aw(20)),
)
```

### 双设计稿场景：`tw()` 用于平板稿

当手机和平板有两套独立设计稿时：

```dart
AdaptiveLayoutBuilder(
  // 手机端：按手机设计稿（375）缩放
  compact: (_) => Padding(
    padding: EdgeInsets.all(16.w),
    child: Text('标题', style: TextStyle(fontSize: 18.sp)),
  ),
  // 平板端：按平板设计稿（768）缩放
  medium: (_) => Padding(
    padding: EdgeInsets.all(ResponsiveUtils.tw(24)),
    child: Text('标题', style: TextStyle(fontSize: 20)),  // 平板不缩放字体
  ),
)
```

### 平板端布局：用固定 dp 值

如果没有独立的平板设计稿，平板端直接用 dp 值：

```dart
AdaptiveLayoutBuilder(
  compact: (_) => Padding(padding: EdgeInsets.all(16.w)),
  medium: (_) => Padding(padding: EdgeInsets.all(24)),     // 直接用 dp
)
```

## 实际使用示例

### 1. 基础组件

```dart
Container(
  padding: EdgeInsets.all(16.w),
  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12.r),
  ),
  child: Column(
    children: [
      Text('标题', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
      SizedBox(height: 8.w),
      Text('内容', style: TextStyle(fontSize: 14.sp)),
    ],
  ),
)
```

### 2. 响应式按钮

```dart
SizedBox(
  width: double.infinity,
  height: 48.h,
  child: FilledButton(
    onPressed: () {},
    style: FilledButton.styleFrom(
      textStyle: TextStyle(fontSize: 16.sp),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
    ),
    child: Text('提交'),
  ),
)
```

### 3. 列表项

```dart
Container(
  height: 72.h,
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
  child: Row(
    children: [
      Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.grey[200],
        ),
        child: Icon(Icons.person, size: 24.w),
      ),
      SizedBox(width: 12.w),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('用户名', style: TextStyle(fontSize: 16.sp)),
            SizedBox(height: 4.h),
            Text('副标题', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          ],
        ),
      ),
    ],
  ),
)
```

### 4. 表单页（手机 + 平板适配）

```dart
@RoutePage()
class MyFormPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('表单')),
      // ContentConstraint 限制大屏上内容宽度
      body: ContentConstraint(
        maxWidth: ResponsiveUtils.maxWidthForm,  // 480dp
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              TextField(
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(labelText: '用户名'),
              ),
              SizedBox(height: 16.w),
              TextField(
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(labelText: '密码'),
                obscureText: true,
              ),
              SizedBox(height: 24.w),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: FilledButton(onPressed: () {}, child: Text('登录')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 最佳实践

### 1. 单位选择原则

| 用途 | 推荐单位 | 说明 |
|------|---------|------|
| 水平间距 / 宽度 | `.w` 或 `aw()` | 大屏共用代码用 `aw()` |
| 垂直间距 / 高度 | `.h` 或 `.w` | 小间距用 `.w` 保持一致 |
| 字体大小 | `.sp` | 平板端自动不缩放 |
| 圆角 | `.r` | 取 w/h 较小缩放比 |
| 平板设计稿值 | `tw()` | 仅双设计稿场景 |
| 布局结构 | `Expanded` / `Flex` | 不要用 `.w` 做布局 |

### 2. ScreenUtil 只管微观尺寸

```dart
// ✅ 微观尺寸：间距、字体、圆角
padding: EdgeInsets.all(16.w),
fontSize: 14.sp,
borderRadius: BorderRadius.circular(8.r),

// ✅ 布局结构：用 Expanded / FractionallySizedBox
Row(children: [
  Expanded(flex: 35, child: masterList),
  Expanded(flex: 65, child: detailPanel),
])

// ❌ 不要用 ScreenUtil 做布局判断
if (1.sw > 600) { ... }  // 不要这样
```

### 3. 断点判断

```dart
// ✅ 页面布局切换：基于 BoxConstraints（推荐）
LayoutBuilder(
  builder: (context, constraints) {
    if (ResponsiveUtils.isCompact(constraints)) { ... }
  },
)

// ✅ 更简洁的写法
AdaptiveBuilder(
  compact: MobileLayout(),
  medium: TabletLayout(),
)

// ✅ 全局配置：基于 BuildContext
final padding = ResponsiveUtils.screenValueOf(
  context,
  compact: 16.w,
  medium: 32,
  expanded: 48,
);

// ❌ 不要用 ScreenUtil 判断设备类型
if (ScreenUtil().screenWidth > 600) { ... }
```

### 4. 性能优化

- 避免在 `build` 中重复创建 `ScreenUtil()` 实例——扩展方法（`.w`/`.sp`）内部已缓存
- 使用 `const` 构造函数减少重建
- 复杂布局的响应式计算可缓存到局部变量

### 5. 测试不同屏幕

```dart
// 使用 Flutter Inspector 切换设备模拟器
// 或安装 device_preview 插件进行实时预览

// 推荐测试的设备尺寸：
// - 手机竖屏：375 × 812（iPhone 13 mini）
// - 手机横屏：812 × 375
// - 平板竖屏：768 × 1024（iPad）
// - 平板横屏：1024 × 768
```

## 常见问题

### Q: 为什么平板上字体没有缩放？

A: 这是有意设计。`fontSizeResolver` 在屏幕宽度 >= 600dp 时直接返回原始 dp 值，因为平板屏幕本身足够大，不需要字体缩放。如果需要缩放，可以在平板布局中手动设置更大的字体值。

### Q: `.w` 在平板上值会不会过大？

A: 会。ScreenUtil 的 `.w` 基于 375 设计稿缩放，在 768dp 宽的平板上会放大约 2 倍。解决方案：
- 平板布局中直接用固定 dp 值
- 共用代码中用 `ResponsiveUtils.aw()` 限制缩放上限
- 使用 `AdaptiveBuilder` 为平板提供独立布局

### Q: 什么时候用 `aw()` vs `.w` vs 固定 dp？

A: 按场景选择：

| 场景 | 推荐 |
|------|------|
| 仅手机端的代码 | `.w` |
| 手机端代码可能在大屏运行 | `aw()` |
| 平板端独立布局 | 固定 dp 或 `tw()` |
| 所有设备通用的小值（2-4dp 间距） | 固定 dp |

### Q: 如何处理横屏适配？

A: 使用 `MediaQuery.orientationOf(context)` 判断方向。项目已配置平板允许横屏、手机仅竖屏（见 `app_initializer.dart`）。

### Q: 如何处理折叠屏？

A: `ScreenUtilInit` 已配置 `splitScreenMode: true`。布局切换使用 `LayoutBuilder`（基于约束的方法），会自动响应折叠屏的分屏宽度变化。
