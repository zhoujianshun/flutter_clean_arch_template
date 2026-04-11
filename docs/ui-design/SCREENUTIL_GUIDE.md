# Flutter ScreenUtil 响应式设计指南

本指南介绍如何在项目中使用 `flutter_screenutil` 实现响应式设计，确保应用在不同屏幕尺寸下都有完美的显示效果。

## 概述

`flutter_screenutil` 是一个用于屏幕适配的 Flutter 插件，它可以让你的UI在不同尺寸的屏幕上显示一致的效果。

### 核心概念

- **设计稿适配**：基于设计稿尺寸进行适配
- **响应式单位**：使用 `.w`、`.h`、`.sp`、`.r` 等单位
- **屏幕适配**：自动根据屏幕尺寸调整UI元素
- **适老化支持**：针对老年用户优化的响应式设计

## 初始化配置

### 1. 依赖配置

```yaml
dependencies:
  flutter_screenutil: ^5.9.3
```

### 2. 初始化设置

在 `main.dart` 中初始化 ScreenUtil：

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      // 设计稿尺寸（iPhone 14 Pro）
      designSize: const Size(393, 852),
      // 最小文字适配
      minTextAdapt: true,
      // 支持分屏
      splitScreenMode: true,
      // 适配方向
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MaterialApp.router(
          // ... 其他配置
        );
      },
    );
  }
}
```

### 3. 设计稿尺寸选择

推荐的设计稿尺寸：

- **iPhone 14 Pro**: 393 × 852
- **iPhone 13/14**: 390 × 844  
- **通用移动端**: 375 × 812

## 响应式单位

### 基础单位

```dart
// 宽度适配
100.w  // 相对于屏幕宽度的100个单位

// 高度适配
100.h  // 相对于屏幕高度的100个单位

// 字体大小适配
16.sp  // 相对于屏幕宽度的字体大小

// 圆角适配
8.r    // 相对于屏幕宽度的圆角大小
```

### 屏幕信息获取

```dart
// 屏幕宽度
double screenWidth = 1.sw;  // 等于 ScreenUtil().screenWidth

// 屏幕高度
double screenHeight = 1.sh; // 等于 ScreenUtil().screenHeight

// 状态栏高度
double statusBarHeight = ScreenUtil().statusBarHeight;

// 底部安全区域高度
double bottomBarHeight = ScreenUtil().bottomBarHeight;
```

## 主题系统集成

### 更新后的主题系统

我们的主题系统已经集成了 ScreenUtil：

```dart
/// 字体样式 - 使用响应式单位
class AppTextStyles {
  static TextStyle get h1 => TextStyle(
    fontSize: 32.sp,  // 响应式字体大小
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );
}

/// 间距系统 - 使用响应式单位
class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
}

/// 圆角系统 - 使用响应式单位
class AppBorderRadius {
  static double get xs => 4.r;
  static double get sm => 8.r;
  static double get md => 12.r;
  static double get lg => 16.r;
}
```

## 响应式工具类

### ResponsiveUtils 使用

```dart
import 'package:sky_harbor_service_app/core/utils/responsive_utils.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 设备类型判断
    bool isMobile = ResponsiveUtils.isMobile(context);
    bool isTablet = ResponsiveUtils.isTablet(context);
    bool isDesktop = ResponsiveUtils.isDesktop(context);

    // 响应式数值
    int columns = ResponsiveUtils.getColumns(context);
    double padding = ResponsiveUtils.getHorizontalPadding(context);

    // 适老化配置
    double elderlyButtonHeight = ResponsiveUtils.getElderlyButtonHeight(context);
    double touchTarget = ResponsiveUtils.getElderlyTouchTarget(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: GridView.count(
        crossAxisCount: columns,
        children: [...],
      ),
    );
  }
}
```

### 响应式构建器

```dart
// 根据屏幕尺寸显示不同布局
ResponsiveBuilder(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)

// 响应式数值选择
int columns = ResponsiveUtils.responsiveValue(
  context,
  mobile: 1,
  tablet: 2,
  desktop: 3,
);
```

## 实际使用示例

### 1. 基础组件适配

```dart
class MyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,           // 响应式宽度
      height: 200.h,          // 响应式高度
      padding: EdgeInsets.all(AppSpacing.md),  // 响应式内边距
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),  // 响应式圆角
        color: AppAdaptiveColors.surface(context),
      ),
      child: Column(
        children: [
          Text(
            '标题',
            style: AppTextStyles.h4,  // 响应式字体
          ),
          SizedBox(height: AppSpacing.sm),  // 响应式间距
          Text(
            '内容文字',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
```

### 2. 按钮适配

```dart
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isElderly;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isElderly = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isElderly 
          ? ResponsiveUtils.getElderlyButtonHeight(context)
          : 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          textStyle: isElderly 
              ? AppTextStyles.elderlyButton 
              : AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
```

### 3. 列表适配

```dart
class ResponsiveList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(
        height: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        return Container(
          height: 80.h,
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppAdaptiveColors.surface(context),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppAdaptiveColors.primary100(context),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(
                  Icons.person,
                  size: ResponsiveUtils.getIconSize(context),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      items[index].title,
                      style: AppTextStyles.bodyMedium,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      items[index].subtitle,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 4. 表单适配

```dart
class ResponsiveForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        children: [
          // 响应式输入框
          TextField(
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              labelText: '用户名',
              hintText: '请输入用户名',
              prefixIcon: Icon(
                Icons.person,
                size: ResponsiveUtils.getIconSize(context),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // 响应式按钮
          ResponsiveButton(
            text: '登录',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
```

## 适老化响应式设计

### ElderlyResponsiveWidget 使用

```dart
class ElderlyFriendlyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElderlyResponsiveWidget(
      fontScale: 1.3,  // 字体放大30%
      enableLargeTouch: true,  // 启用大触摸目标
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                '适老化标题',
                style: AppTextStyles.elderlyH1,
              ),
              SizedBox(height: AppSpacing.xl),
              
              // 适老化按钮
              SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.getElderlyButtonHeight(context),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    textStyle: AppTextStyles.elderlyButton,
                  ),
                  child: Text('大按钮'),
                ),
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

### 1. 单位使用原则

- **宽度/高度**: 使用 `.w` 和 `.h`
- **字体大小**: 使用 `.sp`
- **圆角**: 使用 `.r`
- **间距**: 优先使用 `AppSpacing` 常量

### 2. 响应式断点

```dart
// 屏幕尺寸断点
static const double mobileBreakpoint = 600;
static const double tabletBreakpoint = 1024;
static const double desktopBreakpoint = 1440;

// 使用示例
if (ResponsiveUtils.isMobile(context)) {
  // 手机布局
} else if (ResponsiveUtils.isTablet(context)) {
  // 平板布局
} else {
  // 桌面布局
}
```

### 3. 性能优化

- 避免在 `build` 方法中频繁调用响应式计算
- 使用 `const` 构造函数和常量
- 缓存复杂的响应式计算结果

### 4. 测试不同屏幕

```dart
// 调试时打印屏幕信息
ResponsiveUtils.printScreenInfo(context);

// 模拟不同设备
// 在 Flutter Inspector 中切换设备
// 或使用 Device Preview 插件
```

## 常见问题

### Q: 为什么有些组件显示异常？

A: 确保在 `MaterialApp` 外层包装了 `ScreenUtilInit`，并且设置了正确的 `designSize`。

### Q: 如何处理横屏适配？

A: 使用 `ResponsiveUtils.isLandscape(context)` 判断方向，并提供不同的布局。

### Q: 适老化模式如何实现？

A: 使用 `ElderlyResponsiveWidget` 包装组件，或手动设置更大的字体和触摸目标。

### Q: 如何在不同设备上测试？

A: 使用 Flutter Inspector 的设备切换功能，或安装 Device Preview 插件。

## 总结

通过集成 `flutter_screenutil`，我们的应用现在具备了：

1. **完整的响应式设计**：支持各种屏幕尺寸
2. **统一的设计系统**：使用响应式单位的主题系统
3. **适老化支持**：针对老年用户的特殊优化
4. **强大的工具类**：简化响应式开发

这确保了应用在任何设备上都能提供优秀的用户体验。
