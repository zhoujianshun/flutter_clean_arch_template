# 响应式模块源码详解

> 面向零基础的 Flutter 开发者，从"为什么需要响应式"到"每一行代码做了什么"的完整教学。
>
> 模块路径：`lib/core/responsive/`（6 文件，~1100 行）

---

## 目录

- [前置知识](#前置知识)
- [模块全景](#模块全景)
- [第 1 层：breakpoints.dart——断点体系](#第-1-层breakpointsdart断点体系)
  - [1.1 WindowSizeClass 枚举](#11-windowsizeclass-枚举)
  - [1.2 ResponsiveBreakpoints 工具类](#12-responsivebreakpoints-工具类)
  - [1.3 BreakpointConfig 配置注入](#13-breakpointconfig-配置注入)
  - [1.4 ResponsiveContextX 扩展](#14-responsivecontextx-扩展)
- [第 2 层：adaptive_builder.dart——布局切换](#第-2-层adaptive_builderdart布局切换)
  - [2.1 AdaptiveBuilder](#21-adaptivebuilder)
  - [2.2 AdaptiveLayoutBuilder](#22-adaptivelayoutbuilder)
  - [2.3 ConstraintsScope](#23-constraintsscope)
- [第 3 层：responsive_tokens.dart——尺寸缩放](#第-3-层responsive_tokensdart尺寸缩放)
  - [3.1 设计问题](#31-设计问题)
  - [3.2 of(context) 工厂方法](#32-ofcontext-工厂方法)
  - [3.3 space / font / fixedSize 三种缩放策略](#33-space--font--fixedsize-三种缩放策略)
  - [3.4 ScreenUtil 安全回退](#34-screenutil-安全回退)
- [第 4 层：fold_aware.dart——折叠屏适配](#第-4-层fold_awaredart折叠屏适配)
  - [4.1 FoldInfo 数据类](#41-foldinfo-数据类)
  - [4.2 FoldAwareBuilder](#42-foldawarebuilder)
  - [4.3 HingePaneLayout](#43-hingepanelayout)
  - [4.4 嵌套保护机制](#44-嵌套保护机制)
- [第 5 层：辅助组件](#第-5-层辅助组件)
  - [5.1 ContentConstraint](#51-contentconstraint)
  - [5.2 LayoutSemantics](#52-layoutsemantics)
- [数据流全图](#数据流全图)
- [常见场景实战](#常见场景实战)

---

## 前置知识

在阅读源码之前，你需要理解以下 Flutter 基础概念：

### LayoutBuilder

```dart
LayoutBuilder(
  builder: (BuildContext context, BoxConstraints constraints) {
    // constraints.maxWidth = 父组件分配给你的最大宽度
    // 这个值会扣除 SafeArea、NavigationRail 等占用
    return Text('可用宽度: ${constraints.maxWidth}');
  },
)
```

`LayoutBuilder` 是 Flutter 中获取**局部约束**的标准方式。它的 `constraints` 代表"当前组件最多能用多大的空间"。

### MediaQuery

```dart
final windowWidth = MediaQuery.sizeOf(context).width;
// 返回整个窗口/屏幕的宽度，不扣除任何东西
```

`MediaQuery` 返回**窗口级**信息。窗口宽度 ≠ 组件可用宽度。

### InheritedWidget

```dart
// 定义
class MyConfig extends InheritedWidget {
  final int value;
  // ...
  static MyConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyConfig>()!;
  }
}

// 注入（在树上方）
MyConfig(value: 42, child: MyApp())

// 读取（在树下方的任意位置）
final config = MyConfig.of(context); // O(1) 查找
```

`InheritedWidget` 是 Flutter 的"依赖注入"机制，**向下传递数据**给子树中的任意组件，查找是 O(1) 的。

### 为什么不能只用 MediaQuery？

假设你的 App 在 iPad 上有一个 NavigationRail（宽 72dp）：

```
┌──────────────────────────────────────┐
│  NavigationRail │     内容区域        │
│     (72dp)      │    (696dp)         │
│                 │                    │
│  MediaQuery: 768dp（整个窗口）         │
│  LayoutBuilder: 696dp（实际可用）      │
└──────────────────────────────────────┘
```

如果用 `MediaQuery` 的 768dp 判断为 medium 并渲染双列布局，但实际内容区只有 696dp，可能导致溢出。用 `LayoutBuilder` 的 696dp 才是正确的判断依据。

---

## 模块全景

```
breakpoints.dart ← adaptive_builder.dart ← responsive_tokens.dart
                 ← fold_aware.dart
                 ← content_constraint.dart（via responsive_tokens）
layout_semantics.dart（独立）
```

**依赖方向**：从左到右。`breakpoints.dart` 是最底层，不依赖模块内其他文件。

**阅读顺序**：建议按本文档的章节顺序，从第 1 层到第 5 层。每一层建立在前一层之上。

---

## 第 1 层：breakpoints.dart——断点体系

> 这是整个模块的**地基**，定义了"宽度如何映射到尺寸类"的规则。

### 1.1 WindowSizeClass 枚举

```dart
enum WindowSizeClass { compact, medium, expanded }
```

对应 [Material 3 Window Size Classes](https://m3.material.io/foundations/layout/applying-layout/window-size-classes) 规范：

| 枚举值 | 宽度范围 | 典型设备 |
|--------|---------|---------|
| `compact` | < 600dp | 手机竖屏 |
| `medium` | 600–839dp | 平板竖屏、手机横屏 |
| `expanded` | ≥ 840dp | 平板横屏、桌面 |

M3 还有 large (1200dp) 和 extra-large (1600dp)，本项目暂归入 expanded。

### 1.2 ResponsiveBreakpoints 工具类

这是**所有断点判定的单一入口**。私有构造函数 `ResponsiveBreakpoints._()` 表示不允许实例化，只用静态方法。

#### fromWidth——纯函数后备

```dart
static WindowSizeClass fromWidth(double width) {
  if (width >= expanded) return WindowSizeClass.expanded;  // ≥ 840
  if (width >= compact) return WindowSizeClass.medium;      // ≥ 600
  return WindowSizeClass.compact;                           // < 600
}
```

**不读 context**，用默认阈值 600/840。仅用于无法获取 context 的底层场景（如 `main.dart` 的 `fontSizeResolver` 回调）。

#### fromConstraints——页面级核心方法

```dart
static WindowSizeClass fromConstraints(
  BuildContext context,
  BoxConstraints constraints,
) {
  // 防御：无界宽度（如横向 ListView 内部）
  if (!constraints.hasBoundedWidth) {
    // debug 模式输出一次性警告，运行时安全回退到 compact
    return WindowSizeClass.compact;
  }
  // 从 widget 树读取 BreakpointConfig 的自定义阈值做分类
  return BreakpointConfig.of(context).classify(constraints.maxWidth);
}
```

**关键设计**：

1. **读取 `BreakpointConfig`**——阈值是可配置的，不是硬编码 600/840
2. **无界宽度防御**——`LayoutBuilder` 在横向可滚动容器中会返回 `maxWidth = double.infinity`，不处理会导致永远返回 expanded
3. **一次性警告**——用 `Set<int>` 记录调用栈 hash，同一位置只警告一次，避免每帧刷屏

#### fromWindowSize——窗口级方法

```dart
static WindowSizeClass fromWindowSize(BuildContext context) {
  return BreakpointConfig.of(context).classify(
    MediaQuery.sizeOf(context).width,
  );
}
```

用 `MediaQuery` 而非 `LayoutBuilder`。**仅用于壳层策略**（如 AppShell 决定用 BottomNavigationBar 还是 NavigationRail）。

#### resolve——统一回退链

```dart
static T resolve<T>({
  required WindowSizeClass windowClass,
  required T compact,
  T? medium,
  T? expanded,
}) {
  return switch (windowClass) {
    WindowSizeClass.expanded => expanded ?? medium ?? compact,
    WindowSizeClass.medium   => medium ?? compact,
    WindowSizeClass.compact  => compact,
  };
}
```

**这是整个模块最重要的方法之一**。所有"按断点选值"的逻辑都委托给它：

- `AdaptiveBuilder` 选布局 → 调用 `resolve`
- `ResponsiveTokens.space()` 选数值 → 调用 `resolve`
- `valueOf` / `windowValueOf` → 调用 `resolve`

回退方向是**大→小**（expanded → medium → compact），这保证了安全：600dp 窗口如果没有 medium 布局，宁可用 compact（可能利用率低但不溢出），也不用 expanded（几乎必然溢出）。

#### valueOf / windowValueOf——便捷入口

```dart
// 页面级：基于 LayoutBuilder 约束
final padding = ResponsiveBreakpoints.valueOf(
  context, constraints,
  compactValue: 16.0,
  mediumValue: 24.0,
  expandedValue: 32.0,
);

// 窗口级：基于 MediaQuery
final navStyle = ResponsiveBreakpoints.windowValueOf(
  context,
  compactValue: NavStyle.bottom,
  mediumValue: NavStyle.rail,
);
```

它们是 `fromConstraints` + `resolve` 和 `fromWindowSize` + `resolve` 的组合快捷方法。

### 1.3 BreakpointConfig 配置注入

```dart
class BreakpointConfig extends InheritedWidget {
  const BreakpointConfig({
    required super.child,
    this.compactBreakpoint = 600,   // 默认值
    this.expandedBreakpoint = 840,  // 默认值
    this.minPaneWidth = 300,
  }) : assert(compactBreakpoint < expandedBreakpoint);

  WindowSizeClass classify(double width) {
    if (width >= expandedBreakpoint) return WindowSizeClass.expanded;
    if (width >= compactBreakpoint) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  static BreakpointConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BreakpointConfig>()
        ?? const BreakpointConfig(child: SizedBox.shrink());
  }
}
```

**设计要点**：

1. **纯数据容器**——只有 3 个 `double` 字段，没有业务逻辑
2. **`classify` 是纯函数**——仅基于自身字段，不读外部状态
3. **优雅降级**——`of()` 在树中找不到时返回默认实例，调用方完全无感知
4. **assert 保护**——`compactBreakpoint < expandedBreakpoint`，防止配置倒置

**为什么用 InheritedWidget 而不是全局常量？**

- 全局常量不可配置，多品牌/多产品线无法自定义
- 全局常量不可测试——测试中无法注入不同阈值

**为什么不用 Riverpod Provider？**

- `lib/core/responsive/` 是基础设施层，不应依赖状态管理库
- InheritedWidget 是 Flutter SDK 原生能力，零额外依赖
- 断点配置只需要"从上往下传数据"，不需要跨组件的"写"操作

### 1.4 ResponsiveContextX 扩展

```dart
extension ResponsiveContextX on BuildContext {
  WindowSizeClass get windowSizeClass =>
      ResponsiveBreakpoints.fromWindowSize(this);

  bool get isCompactWindow => windowSizeClass == WindowSizeClass.compact;
  bool get isMediumWindow  => windowSizeClass == WindowSizeClass.medium;
  bool get isExpandedWindow => windowSizeClass == WindowSizeClass.expanded;

  bool get hasAsymmetricHorizontalPadding {
    final p = MediaQuery.paddingOf(this);
    return p.left != p.right;
  }
}
```

语法糖，让壳层代码更简洁：`context.isCompactWindow` 比 `ResponsiveBreakpoints.isCompactWindow(context)` 更好读。

`hasAsymmetricHorizontalPadding` 是为 iPhone Duo 等折叠屏设计的——内屏横屏时右侧有 84dp 的系统控件条，导致左右 SafeArea padding 不对称。

---

## 第 2 层：adaptive_builder.dart——布局切换

> 把"宽度判定"变成"布局选择"，并向子树注入约束信息。

### 2.1 AdaptiveBuilder

```dart
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({
    required this.compact,    // Widget，必传
    this.medium,              // Widget?，可选
    this.expanded,            // Widget?，可选
  });

  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 第一步：判定当前宽度属于哪个尺寸类
        final windowClass = ResponsiveBreakpoints.fromConstraints(
          context, constraints,
        );
        // 第二步：按尺寸类选择布局（带回退）
        final child = ResponsiveBreakpoints.resolve<Widget>(
          windowClass: windowClass,
          compact: compact,
          medium: medium,
          expanded: expanded,
        );
        // 第三步：注入 ConstraintsScope，让子树可以读取约束
        return ConstraintsScope(
          constraints: constraints,
          windowClass: windowClass,
          child: child,
        );
      },
    );
  }
}
```

**三步走**：判定 → 选择 → 注入。这是模块最核心的使用模式。

**使用示例**：

```dart
// 最常见用法：手机一栏、平板两栏
AdaptiveBuilder(
  compact: ArticleListPage(),
  medium: MasterDetailPage(),
)
// compact 时渲染列表页；medium/expanded 时渲染主从分栏页
// expanded 没传？resolve 自动回退到 medium
```

### 2.2 AdaptiveLayoutBuilder

与 `AdaptiveBuilder` 完全相同的断点和回退逻辑，但传的是 **Builder 回调**而非 Widget：

```dart
AdaptiveLayoutBuilder(
  compact: (_) => MobileList(),
  medium: (constraints) => SplitLayout(
    masterWidth: constraints.maxWidth * 0.4,  // 需要 constraints 做计算
  ),
)
```

当子组件需要用 `constraints` 做进一步计算（如分栏比例）时使用此版本。

### 2.3 ConstraintsScope

```dart
class ConstraintsScope extends InheritedWidget {
  final BoxConstraints constraints;
  final WindowSizeClass windowClass;

  double get localWidth => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : double.infinity;
}
```

**它解决了什么问题？**

`LayoutBuilder` 的约束**只在 builder 回调内可用**。如果子组件（比如 `AdaptiveBuilder` 子树深处的一个按钮）需要知道"我在什么尺寸类下"，要么自己再嵌套一层 `LayoutBuilder`（重复计算），要么通过 `ConstraintsScope` 读取。

`AdaptiveBuilder` / `AdaptiveLayoutBuilder` / `FoldAwareBuilder` 在 builder 内部**自动注入** `ConstraintsScope`，子树中的任何组件都可以：

```dart
// 方式 1：直接读
final scope = ConstraintsScope.of(context);
final isLocallyCompact = scope.windowClass == WindowSizeClass.compact;

// 方式 2：通过 ResponsiveTokens（推荐）
final tokens = ResponsiveTokens.of(context);  // 内部自动读 ConstraintsScope
final padding = tokens.space(16, medium: 24);
```

**`of` vs `maybeOf`**：

- `of(context)` 在找不到时**抛出结构化错误**（包含 ErrorSummary + ErrorDescription + ErrorHint），帮助开发者定位问题
- `maybeOf(context)` 在找不到时返回 **null**——`ResponsiveTokens.of` 内部用的就是 `maybeOf`，因为在 `AdaptiveBuilder` 外面调用 token 也是合法的

**`updateShouldNotify` 为什么比较完整 constraints？**

```dart
bool updateShouldNotify(ConstraintsScope oldWidget) {
  return constraints != oldWidget.constraints;
}
```

虽然多数场景只关心宽度，但 `constraints` 是公开字段，调用方可能读取 `maxHeight`。如果只比较宽度，高度变化时不会通知消费方，引入正确性风险。多出的重建成本在 Flutter 的 rebuild 模型下可忽略。

---

## 第 3 层：responsive_tokens.dart——尺寸缩放

> 把"尺寸类"变成"具体的 dp 数值"，处理手机/平板的缩放差异。

### 3.1 设计问题

**核心矛盾**：手机端需要按设计稿缩放（iPhone SE 320dp 和 iPhone Pro Max 430dp 用不同间距），但平板端**不能**缩放（否则 `16dp` 在 iPad Pro 12.9" 上变成 `43dp`，间距过大）。

更复杂的场景：iPad 上有一个 NavigationRail 旁的内容面板，宽度只有 400dp（看起来像手机宽度），但设备本身是平板——这时候应该按"手机"缩放还是"平板"固定 dp？

**答案**：固定 dp。因为用户手持平板，眼睛离屏幕更远，DPI 更高，不应该再缩放。

### 3.2 of(context) 工厂方法

```dart
static ResponsiveTokens of(BuildContext context) {
  // 1. 尝试读取局部约束（AdaptiveBuilder 注入的）
  final scope = ConstraintsScope.maybeOf(context);

  // 2. 读取断点配置
  final config = BreakpointConfig.of(context);

  // 3. 读取全局窗口宽度
  final globalWindowWidth = MediaQuery.sizeOf(context).width;

  // 4. 用配置的阈值分类全局窗口宽度
  final globalClass = config.classify(globalWindowWidth);

  // 5. 局部尺寸类优先，没有局部就用全局
  final windowClass = scope?.windowClass ?? globalClass;

  // 6. 全局窗口是否为 compact？（区分"真手机"和"大屏窄面板"）
  final isGloballyCompact = globalClass == WindowSizeClass.compact;

  return ResponsiveTokens._(
    windowClass: windowClass,
    isGloballyCompact: isGloballyCompact,
    globalWindowWidth: globalWindowWidth,
  );
}
```

**同时读两个信号**——局部约束（`ConstraintsScope`）和全局窗口（`MediaQuery`）。局部告诉你"组件当前可用多宽"，全局告诉你"设备是手机还是平板"。

### 3.3 space / font / fixedSize 三种缩放策略

#### 决策矩阵

| 局部 windowClass | 全局 isGloballyCompact | `space()` | `font()` | `fixedSize()` |
|------------------|----------------------|-----------|----------|---------------|
| compact | true（真手机） | 设计稿缩放 × clamp | ScreenUtil sp | 固定 dp |
| compact | false（大屏窄面板） | 固定 dp | 固定 dp | 固定 dp |
| medium / expanded | — | 固定 dp | 固定 dp | 固定 dp |

#### space()——间距/尺寸缩放

```dart
double space(double compact, {double? medium, double? expanded}) {
  if (windowClass == WindowSizeClass.compact) {
    // 真手机：按设计稿缩放（窗口宽度/375，clamp 0.85–1.15）
    // 大屏窄面板：固定 dp，不缩放
    return isGloballyCompact ? _compact(compact) : compact;
  }
  // medium/expanded：用 resolve 回退链选固定 dp 值
  return ResponsiveBreakpoints.resolve(...);
}
```

`_compact()` 的计算：`值 × (全局窗口宽度 / 375).clamp(0.85, 1.15)`

**为什么 clamp 0.85–1.15？**
- 下限 0.85：iPad Mini 分屏 1/3 时 ScreenUtil 算出 ≈ 0.7x，所有文字按钮缩到不可读。0.85 保证最小可读性
- 上限 1.15：iPhone Pro Max (430dp) 算出 ≈ 1.15x，防止过度放大

#### font()——字体缩放

```dart
double font(double compact, {double? medium, double? expanded}) {
  if (windowClass == WindowSizeClass.compact) {
    return isGloballyCompact ? _setSpSafe(compact) : compact;
  }
  return ResponsiveBreakpoints.resolve(...);
}
```

字体缩放委托 `ScreenUtil().setSp()`，它内部还会考虑系统字体缩放因子。`_setSpSafe` 是安全包装，ScreenUtil 未初始化时回退固定 dp。

#### fixedSize()——不缩放

```dart
double fixedSize(double compact, {double? medium, double? expanded}) {
  return ResponsiveBreakpoints.resolve(...);
}
```

所有断点都不缩放，直接用 `resolve` 选值。适用于主题定义（如图标大小 24dp，所有设备一致）。

### 3.4 ScreenUtil 安全回退

```dart
static double _setSpSafe(double value) {
  try {
    return ScreenUtil().setSp(value);
  } on Error catch (e) {
    // ScreenUtil 未初始化时会抛 late 初始化错误
    // 该错误类型未公开导出，只能按 runtimeType 名称匹配
    final typeName = e.runtimeType.toString();
    if (typeName != 'LateError' && typeName != 'LateInitializationError') {
      rethrow;  // 不是 late 错误，继续抛
    }
    // 安全回退：输出一次性警告，返回固定 dp
    return value;
  }
}
```

**为什么要这么复杂？** ScreenUtil 的内部状态是 `late` 字段，如果根部没有 `ScreenUtilInit`，访问时会抛 `LateError`。但这个错误类型没有公开导出（VM 上叫 `LateError`，dart2js 上叫 `LateInitializationError`），无法写 `on LateError catch`，只能 `on Error catch` 然后按名字过滤。

---

## 第 4 层：fold_aware.dart——折叠屏适配

> 处理 Galaxy Fold、Surface Duo 等有物理铰链的折叠屏设备。

### 4.1 FoldInfo 数据类

```dart
@immutable
class FoldInfo {
  final Rect? obstruction;  // 物理铰链的遮挡区域（全局坐标）
  final Rect? foldCrease;   // 折痕区域（不遮挡，仅参考）
  final bool isHalfOpened;  // 是否半开姿态（帐篷/笔记本形态）
  final List<DisplayFeature> features;  // 完整特征列表

  static const FoldInfo none = FoldInfo();  // 非折叠屏的默认值
}
```

**`obstruction` vs `foldCrease`**：
- `obstruction`：物理铰链（Galaxy Fold），**会遮挡屏幕内容**，必须避让
- `foldCrease`：折痕（连续屏折叠处），不遮挡内容，仅作为对齐参考线

#### fromContext 工厂方法

```dart
factory FoldInfo.fromContext(BuildContext context) {
  final rawFeatures = MediaQuery.displayFeaturesOf(context);
  // 遍历所有 DisplayFeature：
  // - hinge → 记录 obstruction
  // - fold → 记录 foldCrease
  // - cutout（摄像头开孔）→ 忽略
  // 如果任何 feature 处于 halfOpened 状态 → isHalfOpened = true
}
```

**平台限制**：iOS 上 `displayFeaturesOf` 恒返回空列表（flutter/flutter#192515），所以 `FoldInfo` 在 iOS 上恒为 `none`。

#### axis 属性

```dart
FoldAxis? get axis {
  final bounds = obstruction ?? foldCrease;
  if (bounds == null) return null;
  return bounds.width > bounds.height
      ? FoldAxis.horizontal   // 宽 > 高 → 水平铰链 → 上下分栏
      : FoldAxis.vertical;    // 高 > 宽 → 垂直铰链 → 左右分栏
}
```

从铰链 bounds 的宽高比推导方向——不硬编码"折叠屏一定是左右分"。

### 4.2 FoldAwareBuilder

`FoldAwareBuilder` = `AdaptiveBuilder` + `FoldInfo`。它的 builder 回调同时接收 `BoxConstraints` 和 `FoldInfo`：

```dart
FoldAwareBuilder(
  compact: (constraints, fold) => ListPage(),
  medium: (constraints, fold) => HingePaneLayout(
    first: MasterList(),
    second: DetailView(),
    fallback: SplitView(ratio: 0.4),
  ),
)
```

#### 嵌套保护核心逻辑

```dart
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final rawFold = FoldInfo.fromContext(context);
      final windowSize = MediaQuery.sizeOf(context);

      // 按铰链轴向检查是否覆盖完整窗口
      final coversWindowAxis = switch (rawFold.axis) {
        // 水平铰链（上下分栏）→ 检查高度是否覆盖窗口
        FoldAxis.horizontal => _coversWindow(constraints, windowSize, Axis.vertical),
        // 垂直铰链（左右分栏）或无铰链 → 检查宽度是否覆盖窗口
        FoldAxis.vertical || null => _coversWindow(constraints, windowSize, Axis.horizontal),
      };

      // 不覆盖 → 说明是嵌套场景，铰链全局坐标不可用，安全回退
      final fold = coversWindowAxis ? rawFold : FoldInfo.none;
      // ... 后续与 AdaptiveBuilder 相同
    },
  );
}
```

**为什么需要嵌套保护？** 铰链的 `obstruction.left` 是**窗口级全局坐标**。如果组件嵌套在 NavigationRail 旁边（自身宽度 < 窗口宽度），用全局坐标分栏会把分割线放在错误的位置。

### 4.3 HingePaneLayout

```dart
class HingePaneLayout extends StatelessWidget {
  final Widget first;     // 铰链左侧（垂直）或上方（水平）
  final Widget second;    // 铰链右侧（垂直）或下方（水平）
  final Widget fallback;  // 非折叠设备的默认布局
  final double hingeMargin;  // 铰链两侧的额外间距
}
```

**分栏逻辑（以垂直铰链为例）**：

```
┌────────────────────────────────────────────┐
│   first    │ hinge │        second          │
│            │(遮挡) │                        │
│ width =    │       │  Expanded（自动填充）    │
│ hinge.left │       │                        │
│ - margin   │       │                        │
└────────────────────────────────────────────┘
```

```dart
// 垂直铰链 → 用 Row 左右分栏
Row(
  children: [
    SizedBox(width: hinge.left - hingeMargin, child: first),
    SizedBox(width: hinge.width + hingeMargin * 2),  // 铰链 + 间距
    Expanded(child: second),  // 右侧自动填充
  ],
)
```

**回退到 fallback 的条件**：
1. 无物理铰链（`obstruction == null`）
2. 约束不覆盖完整窗口（嵌套场景）
3. 约束无界
4. 计算出的 pane 尺寸 ≤ 0

### 4.4 嵌套保护机制

模块有两层嵌套保护：

#### 1. 窗口覆盖检测

```dart
bool _coversWindow(BoxConstraints c, Size window, Axis axis) {
  // 检查约束的 maxWidth/maxHeight 是否接近窗口尺寸
  // 容差 0.5dp（吸收浮点精度，但远小于任何真实 UI 组件）
  return local != null && (local - global).abs() < 0.5;
}
```

#### 2. displayFeatures 清洗

```dart
Widget _wrapPaneWithCleanedFeatures(BuildContext context, Widget child) {
  final data = MediaQuery.of(context);
  if (data.displayFeatures.isEmpty) return child;
  return MediaQuery(
    data: data.copyWith(displayFeatures: const []),
    child: child,
  );
}
```

分栏成功后，每个 pane 的子树中 `MediaQuery.displayFeaturesOf` 返回空列表。这防止了嵌套的 `FoldAwareBuilder` / `HingePaneLayout` 重复消费同一铰链。

---

## 第 5 层：辅助组件

### 5.1 ContentConstraint

```dart
ContentConstraint(
  maxWidth: ResponsiveTokens.maxWidthDetail,  // 680dp
  outerPadding: EdgeInsets.symmetric(horizontal: 24),
  child: ArticleBody(),
)
```

手机上父级窄于 680dp，约束不生效（等于没有这个 widget）。平板上父级可能 1024dp，内容被限制在 680dp 并居中——防止文章正文过宽导致阅读体验差。

**关键细节**：`outerPadding` 在 `ConstrainedBox` **外部**（先 `Padding` 再 `ConstrainedBox`），所以总宽度恒 ≤ 父级宽度，不会溢出。

### 5.2 LayoutSemantics

```dart
class LayoutSemantics {
  // NavigationRail 标签显示策略
  static NavigationRailLabelType railLabelType(context, constraints) {
    return ResponsiveBreakpoints.isExpanded(context, constraints)
        ? NavigationRailLabelType.all       // expanded: 显示所有标签
        : NavigationRailLabelType.selected; // compact/medium: 仅显示选中的
  }

  // 主从分栏中左侧主面板的推荐宽度比例
  static double masterPaneRatio(context, constraints) {
    return ResponsiveBreakpoints.isExpanded(context, constraints) ? 0.35 : 0.4;
  }
}
```

**设计意图**：业务页面不要直接写 `if (width > 840) ...`，而是调用 `LayoutSemantics.railLabelType()`。这样如果未来策略变了（比如 medium 也显示所有标签），只改一个地方。

---

## 数据流全图

以一个典型的页面为例，追踪数据流经的每一步：

```
用户在 iPad 上旋转设备（竖屏 → 横屏）
│
▼ Flutter 框架触发 MediaQuery 变化
│
▼ BreakpointConfig（InheritedWidget，树顶部可选注入）
│  └→ 持有阈值 { compact: 600, expanded: 840 }
│
▼ AdaptiveBuilder 内部的 LayoutBuilder 收到新约束
│  constraints.maxWidth = 900dp（扣除 NavigationRail 72dp 后）
│
▼ ResponsiveBreakpoints.fromConstraints(context, constraints)
│  └→ BreakpointConfig.of(context).classify(900) → expanded
│
▼ ResponsiveBreakpoints.resolve(expanded, compact: ..., medium: ..., expanded: ...)
│  └→ 选中 expanded 布局
│
▼ ConstraintsScope 注入到子树
│  └→ { constraints: ..., windowClass: expanded }
│
▼ 子组件调用 ResponsiveTokens.of(context)
│  ├→ 读取 ConstraintsScope → windowClass = expanded
│  ├→ 读取 MediaQuery → globalWindowWidth = 972dp → globalClass = expanded
│  └→ isGloballyCompact = false
│
▼ tokens.space(16, medium: 24, expanded: 32)
│  └→ windowClass = expanded → resolve → 返回 32.0
│
▼ 渲染 expanded 布局，间距 32dp
```

---

## 常见场景实战

### 场景 1：最简单的手机/平板适配

```dart
class MyPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      compact: _CompactLayout(),
      medium: _TabletLayout(),
      // 不传 expanded → expanded 自动回退到 medium
    );
  }
}
```

### 场景 2：需要用约束计算分栏宽度

```dart
AdaptiveLayoutBuilder(
  compact: (_) => SingleColumnList(),
  medium: (constraints) => Row(
    children: [
      SizedBox(
        width: constraints.maxWidth * 0.4,
        child: MasterList(),
      ),
      Expanded(child: DetailView()),
    ],
  ),
)
```

### 场景 3：按断点调整间距

```dart
Widget build(BuildContext context) {
  final tokens = ResponsiveTokens.of(context);
  return Padding(
    padding: EdgeInsets.all(tokens.space(16, medium: 24, expanded: 32)),
    child: ...,
  );
}
```

### 场景 4：折叠屏铰链分栏

```dart
FoldAwareBuilder(
  compact: (_, __) => PhoneLayout(),
  medium: (constraints, fold) => HingePaneLayout(
    first: MasterList(),
    second: DetailView(),
    fallback: Row(  // 非折叠设备的普通分栏
      children: [
        SizedBox(width: constraints.maxWidth * 0.4, child: MasterList()),
        Expanded(child: DetailView()),
      ],
    ),
  ),
)
```

### 场景 5：平板上限制内容宽度

```dart
ContentConstraint(
  maxWidth: ResponsiveTokens.maxWidthDetail,  // 680dp
  child: SingleChildScrollView(
    child: ArticleContent(),
  ),
)
```

### 场景 6：壳层决定导航形态

```dart
// 在 AppShell 中（不在 AdaptiveBuilder 内）
Widget build(BuildContext context) {
  if (context.isCompactWindow) {
    return Scaffold(
      body: child,
      bottomNavigationBar: MyBottomNavigationBar(),
    );
  } else {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            labelType: LayoutSemantics.railLabelType(context, constraints),
            ...
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

### 场景 7：注入自定义断点

```dart
// 在 App 顶层（可选，不注入则使用默认 600/840）
BreakpointConfig(
  compactBreakpoint: 640,   // 自定义：640 以下才算 compact
  expandedBreakpoint: 900,  // 自定义：900 以上才算 expanded
  child: MaterialApp(...),
)
```

注入后，整个子树中的所有 `fromConstraints`、`fromWindowSize`、`AdaptiveBuilder`、`ResponsiveTokens` 都自动使用新阈值——因为它们内部都调用 `BreakpointConfig.of(context).classify()`。
