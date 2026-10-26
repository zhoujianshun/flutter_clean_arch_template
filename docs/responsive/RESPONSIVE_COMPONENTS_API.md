# 响应式适配组件 API 参考

本文档介绍项目中用于手机/平板适配的核心组件和工具类的用法。

## 目录

- [断点定义](#断点定义)
- [ResponsiveBreakpoints 断点工具](#responsivebreakpoints-断点工具)
- [BreakpointConfig 断点配置](#breakpointconfig-断点配置)
- [ResponsiveTokens 设计 Token](#responsivetokens-设计-token)
- [ResponsiveContextX 扩展](#responsivecontextx-扩展)（位于 breakpoints.dart）
- [ConstraintsScope 局部约束](#constraintsscope-局部约束)（位于 adaptive_builder.dart）
- [LayoutSemantics 语义决策](#layoutsemantics-语义决策)
- [AdaptiveBuilder 自适应构建器](#adaptivebuilder-自适应构建器)
- [AdaptiveLayoutBuilder 自适应布局构建器](#adaptivelayoutbuilder-自适应布局构建器)
- [ContentConstraint 内容约束](#contentconstraint-内容约束)
- [折叠屏适配（FoldInfo / FoldAwareBuilder / HingePaneLayout）](#折叠屏适配foldinfo--foldawarebuilder--hingepanelayout)
- [AppShellPage 自适应导航](#appshellpage-自适应导航)
- [示例页面](#示例页面)
- [最佳实践](#最佳实践)

---

## 断点定义

采用 M3 compact/medium/expanded 三个阈值的子集：

| 尺寸类 | 宽度范围 | 典型设备 | 常量 |
|--------|---------|---------|------|
| Compact（紧凑） | < 600dp | 手机 | `ResponsiveBreakpoints.compact` |
| Medium（中等） | 600-839dp | 平板竖屏、折叠屏 | — |
| Expanded（扩展） | ≥ 840dp | 平板横屏、桌面 | `ResponsiveBreakpoints.expanded` |

> desktop / 超宽屏暂统一归入 expanded，后续可通过 `BreakpointConfig` 扩展。

---

## ResponsiveBreakpoints 断点工具

**路径**: `lib/core/responsive/breakpoints.dart`

断点判定的**单一真值源**，提供两套方法：

### 基于 BoxConstraints（推荐）

配合 `LayoutBuilder` 使用，响应父约束（折叠屏/分屏友好），代表**实际可用宽度**。
所有方法均从 `BreakpointConfig` 读取自定义阈值（不存在时使用默认值 600/840）：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (ResponsiveBreakpoints.isCompact(context, constraints)) { ... }
    if (ResponsiveBreakpoints.isMedium(context, constraints)) { ... }
    if (ResponsiveBreakpoints.isExpanded(context, constraints)) { ... }

    final columns = ResponsiveBreakpoints.valueOf(
      context,
      constraints,
      compactValue: 1,
      mediumValue: 2,
      expandedValue: 3,
    );
  },
)
```

### 基于窗口宽度（窗口级策略）

使用 `MediaQuery` 获取完整窗口宽度，**仅用于壳层/全局策略**（如 AppShell 导航形态选择）：

```dart
ResponsiveBreakpoints.isCompactWindow(context);   // < 600dp
ResponsiveBreakpoints.isMediumWindow(context);    // 600-839dp
ResponsiveBreakpoints.isExpandedWindow(context);  // >= 840dp

final padding = ResponsiveBreakpoints.windowValueOf(
  context,
  compactValue: 16.0,
  mediumValue: 32.0,
  expandedValue: 48.0,
);
```

> ⚠️ 不要在页面内使用 `fromWindowSize` 做布局分支——窗口宽度不等于扣除 SafeArea、NavigationRail 等后的实际内容宽度。

### WindowSizeClass 枚举

```dart
final sizeClass = ResponsiveBreakpoints.fromConstraints(context, constraints);
// 或窗口级
final sizeClass = ResponsiveBreakpoints.fromWindowSize(context);

switch (sizeClass) {
  case WindowSizeClass.compact: ...
  case WindowSizeClass.medium: ...
  case WindowSizeClass.expanded: ...
}
```

### tryFromConstraints：安全判定

当约束可能无界时（横向可滚动等场景），使用 `tryFromConstraints` 区分"真正的 compact"和"无法判定"：

```dart
final sizeClass = ResponsiveBreakpoints.tryFromConstraints(context, constraints);
if (sizeClass == null) {
  // 无界宽度，无法判定——使用默认布局
}
```

### 方法列表

| 方法 | 参数 | 返回 | 说明 |
|------|------|------|------|
| `fromWidth` | `double` | `WindowSizeClass` | 按默认阈值分类（无 context，仅底层场景） |
| `fromConstraints` | `BuildContext`, `BoxConstraints` | `WindowSizeClass` | 按约束分类（读 BreakpointConfig，无界警告后回退 compact） |
| `tryFromConstraints` | `BuildContext`, `BoxConstraints` | `WindowSizeClass?` | 同上，但无界时返回 null |
| `fromWindowSize` | `BuildContext` | `WindowSizeClass` | 按窗口宽度分类（读 BreakpointConfig） |
| `isCompact` | `BuildContext`, `BoxConstraints` | `bool` | 约束宽度 < compact 阈值 |
| `isMedium` | `BuildContext`, `BoxConstraints` | `bool` | 约束宽度在 compact–expanded 之间 |
| `isExpanded` | `BuildContext`, `BoxConstraints` | `bool` | 约束宽度 >= expanded 阈值 |
| `isCompactWindow` | `BuildContext` | `bool` | 窗口宽度 < compact 阈值 |
| `isMediumWindow` | `BuildContext` | `bool` | 窗口宽度在 compact–expanded 之间 |
| `isExpandedWindow` | `BuildContext` | `bool` | 窗口宽度 >= expanded 阈值 |
| `valueOf<T>` | `BuildContext`, `BoxConstraints`, `compactValue`, ... | `T` | 按约束返回值（读 BreakpointConfig） |
| `windowValueOf<T>` | `BuildContext`, `compactValue`, ... | `T` | 按窗口宽度返回值 |
| `resolve<T>` | `windowClass`, `compact`, `medium?`, `expanded?` | `T` | 按 WindowSizeClass 解析值（纯回退，无 context） |

### 渐进回退规则

所有断点方法共享统一的回退链（通过 `resolve` 方法）：

- expanded 宽度但 `expanded` 为 null → `medium` → `compact`
- medium 宽度但 `medium` 为 null → **只退到 `compact`**（不会跳到 `expanded`）

避免 600dp 窗口使用为 840dp+ 设计的布局导致溢出。

### 两套方法的选择

| 场景 | 推荐方法 | 原因 |
|------|---------|------|
| 页面布局切换（分栏/单列） | `isCompact(context, constraints)` | 响应父约束，折叠屏/分屏友好 |
| 网格列数 / 间距 | `valueOf(context, constraints, ...)` | 同上 |
| AppShell 导航形态 | `isCompactWindow(context)` | 壳层策略取决于完整窗口 |
| 主题 / 全局配置 | `windowValueOf(context, ...)` | 无 LayoutBuilder 可用 |

---

## BreakpointConfig 断点配置

**路径**: `lib/core/responsive/breakpoints.dart`

可注入的纯数据容器，持有断点阈值和布局参数。`ResponsiveBreakpoints` 的所有需要 `BuildContext` 的方法均从此处读取自定义阈值。不注入时使用默认值（600/840）。

```dart
// 在 App 顶层注入自定义配置（可选）
BreakpointConfig(
  compactBreakpoint: 640,
  expandedBreakpoint: 900,
  minPaneWidth: 320,
  child: MaterialApp(...),
)
```

### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `compactBreakpoint` | `double` | 600 | compact → medium 阈值 |
| `expandedBreakpoint` | `double` | 840 | medium → expanded 阈值 |
| `minPaneWidth` | `double` | 300 | 分栏布局中单个 pane 的最小宽度 |

### 读取配置

```dart
final config = BreakpointConfig.of(context);      // 不存在时返回默认值
final config = BreakpointConfig.maybeOf(context);  // 不存在时返回 null

// 直接分类（纯函数，基于自身阈值）
final sizeClass = config.classify(width);
```

---

## ResponsiveTokens 设计 Token

**路径**: `lib/core/responsive/responsive_tokens.dart`

管理设计稿尺寸、内容宽度常量和缩放方法。

### 用法

```dart
final tokens = ResponsiveTokens.of(context);

// 间距/尺寸：compact 真手机按设计稿缩放，大屏固定 dp
final padding = tokens.space(16, medium: 24, expanded: 32);

// 字体：compact 真手机 sp 缩放，大屏固定 dp
final fontSize = tokens.font(14, medium: 16);

// 固定 dp（所有断点不缩放，适用于主题/全局定义）
final size = tokens.fixedSize(16, medium: 20);
```

### 设计稿尺寸

| 常量 | 值 | 说明 |
|------|-----|------|
| `phoneDesignWidth` | 375 | 手机设计稿宽度 |
| `phoneDesignHeight` | 812 | 手机设计稿高度 |
| `tabletDesignWidth` | 768 | 平板设计稿宽度 |
| `tabletDesignHeight` | 1024 | 平板设计稿高度 |

### 内容最大宽度

| 常量 | 值 | 适用场景 |
|------|-----|------|
| `maxWidthFormNarrow` | 420dp | 窄表单（登录右侧、搜索框） |
| `maxWidthForm` | 480dp | 标准表单（登录/注册） |
| `maxWidthList` | 600dp | 列表/设置页 |
| `maxWidthDetail` | 680dp | 详情/文章页 |

### 实例方法

| 方法 | compact（真手机） | compact（大屏窄面板） | medium/expanded | 说明 |
|------|:---:|:---:|:---:|------|
| `space(compact, medium?, expanded?)` | 缩放（clamp 0.85–1.15） | 固定 dp | 固定 dp | 间距/尺寸 |
| `font(compact, medium?, expanded?)` | sp 缩放（ScreenUtil） | 固定 dp | 固定 dp | 字体 |
| `fixedSize(compact, medium?, expanded?)` | 固定 dp | 固定 dp | 固定 dp | 主题/全局定义 |

> 渐进回退：medium 缺失回退 compact 原值（未缩放），expanded 缺失回退 medium。

### ScreenUtil 依赖契约

- `space` 的 compact 缩放基于窗口级 MediaQuery 宽度（与 `ScreenUtil().screenWidth` 同源等价），**不依赖** ScreenUtil。
- `font` 的 compact 缩放委托 `ScreenUtil().setSp`（保留根部 `ScreenUtilInit` 注入的 `fontSizeResolver` 语义），**要求根部已接线 `ScreenUtilInit`**；未接线时回退固定 dp 并输出一次性 debug 警告，不抛异常。

### 局部约束感知

`ResponsiveTokens.of(context)` 优先使用 `ConstraintsScope`（由 `AdaptiveBuilder` 自动注入）的局部约束宽度做断点判定。不存在时使用 `BreakpointConfig` + 窗口宽度。

**缩放策略**：

| 全局窗口 | 局部约束 | 场景 | compact 端行为 |
|---------|---------|------|---------------|
| compact | compact | 真手机 | 按设计稿缩放 |
| 非 compact | compact | 大屏窄面板 | 固定 dp，不缩放 |

这确保大屏上的窄面板不会因为全局窗口宽度被过度放大。

```dart
// 在 AdaptiveBuilder 的子树中
final tokens = ResponsiveTokens.of(context);
final padding = tokens.space(16, medium: 24);
final fontSize = tokens.font(14, medium: 16);
```

---

## ResponsiveContextX 扩展

**路径**: `lib/core/responsive/breakpoints.dart`（与 `ResponsiveBreakpoints`、`BreakpointConfig` 同文件）

`BuildContext` 的语义化扩展，简化**窗口级**断点读取：

```dart
if (context.isCompactWindow) { ... }
if (context.isMediumWindow) { ... }
if (context.isExpandedWindow) { ... }

final sizeClass = context.windowSizeClass;
```

> 读取的是**窗口级**宽度（`MediaQuery.sizeOf`），适用于壳层和全局策略。
> 页面/组件布局应使用 `ConstraintsScope` 或 `AdaptiveBuilder` 的局部约束。

### iPhone Duo / 非对称安全区辅助属性

```dart
// 安全区左右不对称（iPhone Duo 内屏横屏时右侧有垂直控件条带）
if (context.hasAsymmetricHorizontalPadding) {
  final p = MediaQuery.paddingOf(context);
  // 逐侧处理：p.left 和 p.right 分别应用，不使用 EdgeInsets.symmetric
}
```

> 布局决策应基于可用宽度（断点），不要用 `orientation` 做布局分支。
> iPhone Duo 内屏不遵循 app 声明的方向，`orientation` 不是可靠信号。

---

## ConstraintsScope 局部约束

**路径**: `lib/core/responsive/adaptive_builder.dart`（与 `AdaptiveBuilder`、`AdaptiveLayoutBuilder` 同文件）

`AdaptiveBuilder` / `AdaptiveLayoutBuilder` / `FoldAwareBuilder` 在 `LayoutBuilder` 回调内自动注入，无需手动创建。子树中的组件可读取**局部**约束宽度：

```dart
// 在 AdaptiveBuilder 的子树中
final scope = ConstraintsScope.of(context);
final isLocallyCompact = scope.windowClass == WindowSizeClass.compact;

// 或使用 ResponsiveTokens 的 context-aware 方法
final tokens = ResponsiveTokens.of(context);
final padding = tokens.space(16, medium: 24);
```

### API

| 方法/属性 | 返回 | 说明 |
|---------|------|------|
| `of(context)` | `ConstraintsScope` | 不存在时抛出 `FlutterError`（含修复建议） |
| `maybeOf(context)` | `ConstraintsScope?` | 不存在时返回 null |
| `constraints` | `BoxConstraints` | 当前子树的父级约束 |
| `windowClass` | `WindowSizeClass` | 基于约束计算的尺寸类 |
| `localWidth` | `double` | 约束宽度（无界时返回 `double.infinity`） |

---

## LayoutSemantics 语义决策

**路径**: `lib/core/responsive/layout_semantics.dart`

封装常见的页面层布局语义决策，避免在业务代码中重复判断：

```dart
// NavigationRail 标签策略
NavigationRail(
  labelType: LayoutSemantics.railLabelType(context, constraints),
  // expanded: all, compact/medium: selected
)

// Master-Detail 左侧面板比例
SizedBox(
  width: constraints.maxWidth * LayoutSemantics.masterPaneRatio(context, constraints),
  // expanded: 0.35, medium: 0.4
)
```

---

## AdaptiveBuilder 自适应构建器

**路径**: `lib/core/responsive/adaptive_builder.dart`

声明式地在不同断点切换整个子组件树（子组件不需要 `constraints` 时使用）：

```dart
// 基础用法：手机 vs 平板
AdaptiveBuilder(
  compact: MobileLayout(),      // < 600dp
  medium: TabletLayout(),       // >= 600dp
)

// 三种布局
AdaptiveBuilder(
  compact: PhoneLayout(),       // < 600dp
  medium: TabletLayout(),       // 600-839dp
  expanded: DesktopLayout(),    // >= 840dp
)
```

### 回退规则

渐进回退（同 `AdaptiveLayoutBuilder` / `FoldAwareBuilder`）：

- expanded 宽度但 `expanded` 为 null → 使用 `medium`，再退到 `compact`
- medium 宽度但 `medium` 为 null → **只退到 `compact`**（不会跳到 `expanded`，
  避免中等宽度误渲染桌面级布局）

---

## AdaptiveLayoutBuilder 自适应布局构建器

**路径**: `lib/core/responsive/adaptive_builder.dart`

与 `AdaptiveBuilder` 相同的断点逻辑和回退规则，但通过回调传递 `BoxConstraints`，
允许子组件根据约束值做进一步的布局计算（如分栏比例、宽度值等）：

```dart
// 子组件需要 constraints 计算分栏宽度
AdaptiveLayoutBuilder(
  compact: (_) => MobileList(),
  medium: (c) => SplitLayout(masterWidth: c.maxWidth * 0.4),
)

// 三级布局
AdaptiveLayoutBuilder(
  compact: (_) => CompactView(),
  medium: (c) => MediumView(constraints: c),
  expanded: (c) => ExpandedView(constraints: c),
)
```

### 三者对比

| | AdaptiveBuilder | AdaptiveLayoutBuilder | LayoutBuilder |
|-|:---:|:---:|:---:|
| 用途 | 纯布局切换 | 布局切换 + 约束计算 | 连续值计算 |
| 参数 | Widget | Widget Function(BoxConstraints) | BoxConstraints |
| 状态保持 | 切换时销毁 | 切换时销毁 | — |
| ConstraintsScope | 自动注入 | 自动注入 | 需手动注入 |

### 何时选择哪个

- 子组件不需要 `constraints`，纯切换 → `AdaptiveBuilder`（最简洁）
- 子组件需要 `constraints` 来决定分栏宽度、flex 比例等 → `AdaptiveLayoutBuilder`
- 不是离散分支，而是用 constraints 做连续计算（如列数、间距）→ 直接用 `LayoutBuilder`
- 需要保持跨断点状态（表单输入、滚动位置）→ `AdaptiveBuilder` + 状态上提（Controller / Provider / `PageStorageKey`）

---

## ContentConstraint 内容约束

**路径**: `lib/core/responsive/content_constraint.dart`

在大屏上限制内容最大宽度并居中。手机上无视觉影响。

> **生效条件**：约束仅在**父容器宽度超过 `maxWidth` 时**生效（内容居中、两侧留白）；
> 父宽度不足时子组件自然填满，不产生额外效果。`maxHeight` 同理。

```dart
// 登录页 —— 使用语义化常量
ContentConstraint(
  maxWidth: ResponsiveTokens.maxWidthForm,     // 480dp
  child: LoginForm(),
)

// 详情页 —— 限制阅读宽度
ContentConstraint(
  maxWidth: ResponsiveTokens.maxWidthDetail,   // 680dp
  child: ArticleContent(),
)

// 设置页 —— 带外边距
ContentConstraint(
  maxWidth: ResponsiveTokens.maxWidthList,     // 600dp
  outerPadding: EdgeInsets.all(16),
  child: SettingsList(),
)
```

### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `child` | Widget | 必填 | 子组件 |
| `maxWidth` | double | `ResponsiveTokens.maxWidthList`（600） | 最大宽度限制（dp），必须 > 0 |
| `maxHeight` | double? | null | 最大高度限制（必须 > 0 或 null）；超出由内容滚动接管 |
| `alignment` | Alignment | topCenter | 对齐方式 |
| `outerPadding` | EdgeInsets? | null | 位于 `ConstrainedBox` **外部**的间距 |

> `outerPadding` 位于 `ConstrainedBox` 外部，因此总占用宽度 = `min(parentWidth, maxWidth) + outerPadding.horizontal`。

### 推荐 maxWidth 值

| 页面类型 | 常量 | 值 | 说明 |
|---------|------|-----|------|
| 窄表单（登录右侧） | `ResponsiveTokens.maxWidthFormNarrow` | 420dp | 分栏登录的表单侧 |
| 标准表单（登录/注册） | `ResponsiveTokens.maxWidthForm` | 480dp | 表单不宜过宽 |
| 列表/设置页 | `ResponsiveTokens.maxWidthList` | 600dp | 标准内容宽度 |
| 详情/文章页 | `ResponsiveTokens.maxWidthDetail` | 680dp | 适合长文阅读 |

---

## 折叠屏适配（FoldInfo / FoldAwareBuilder / HingePaneLayout）

**路径**: `lib/core/responsive/fold_aware.dart`

### 核心心智模型

**一般页面适配只需要 `AdaptiveBuilder`。** 折叠屏展开/折叠本质上只是窗口宽度变化
（如 iPhone Duo 折叠态 466dp ↔ 展开态 951dp），断点体系天然覆盖——折叠态走
compact、展开态走 medium/expanded，`AdaptiveBuilder` 的渐进回退自动兜底。

`FoldAwareBuilder` / `HingePaneLayout` **只在布局需要感知铰链位置时使用**：

| 需求 | 用什么 |
|------|--------|
| 支持"折叠屏"（宽度变化适配） | `AdaptiveBuilder`，无需额外代码 |
| 两栏布局需按约束做断点切换 + 铰链对齐 | `FoldAwareBuilder` + `HingePaneLayout` |
| 交互元素（按钮/输入框）必须避开物理铰链遮挡 | `HingePaneLayout` |
| 对话框等浮层避铰链 | 官方 `DisplayFeatureSubScreen` |

### ⚠️ 平台限制：仅 Android 生效

`MediaQuery.displayFeatures` **目前只在 Android 上由系统填充**
（Galaxy Fold / Pixel Fold 等会报告铰链位置）。

- iPhone Duo 上 `FoldInfo` 恒为 `none`，`HingePaneLayout` 恒走 `fallback`
- iOS 的折叠屏适配完全依赖断点体系（466/669/951 → compact/medium/expanded），不依赖本组 API
- 因此 **`fallback` / 比例分栏兜底必须完整可用**——它是绝大多数用户的实际路径

### FoldInfo 姿态数据类

解析 `displayFeatures` 得到语义明确的折叠姿态：

| 字段 | 类型 | 含义 | 来源 |
|------|------|------|------|
| `obstruction` | `Rect?` | 物理铰链遮挡区域 | `DisplayFeatureType.hinge`（`@visibleForTesting`） |
| `foldCrease` | `Rect?` | 折痕参考线（不遮挡） | `DisplayFeatureType.fold`（`@visibleForTesting`） |
| `isHalfOpened` | `bool` | 半开姿态（帐篷/笔记本形态） | `postureHalfOpened` |
| `features` | `List<DisplayFeature>` | 过滤后的折叠特征列表（不可变） | hinge + fold |
| `axis` | `FoldAxis?` | 铰链方向轴（`vertical`/`horizontal`） | 从 bounds 宽高比推导 |
| `isFoldable` | `bool` | 是否折叠屏设备 | — |

> `obstruction` 和 `foldCrease` 标记为 `@visibleForTesting`，业务代码不应直接读取——
> 铰链 bounds 为窗口全局坐标，在嵌套面板中不安全。请通过 `HingePaneLayout` 使用。

### FoldAxis 铰链方向

```dart
enum FoldAxis {
  vertical,    // 垂直铰链——左右分栏（如 Galaxy Fold 展开态）
  horizontal,  // 水平铰链——上下分栏（如笔记本形态/帐篷形态）
}
```

```dart
final fold = FoldInfo.fromContext(context);
if (fold.axis == FoldAxis.vertical) {
  // 左右分栏布局
} else if (fold.axis == FoldAxis.horizontal) {
  // 上下分栏布局
}
```

### FoldAwareBuilder：断点布局 + 折叠感知

在 `AdaptiveLayoutBuilder` 的断点语义上额外暴露 `FoldInfo`，供折叠屏设备做姿态感知的布局决策：

```dart
FoldAwareBuilder(
  compact: (_, __) => const ContactList(),  // 手机：单栏
  medium: (constraints, fold) => HingePaneLayout(
    first: const MasterList(),
    second: const DetailView(),
    fallback: SplitView(ratio: 0.4),  // 非折叠设备走这里
  ),
)
```

回退规则与 `AdaptiveLayoutBuilder` 一致（渐进回退）。

**嵌套保护**：当组件不覆盖完整窗口宽度时（嵌套在 NavigationRail 旁的面板、弹窗等），`FoldAwareBuilder` 自动将 `FoldInfo` 替换为 `FoldInfo.none`，避免全局坐标被误用为局部分栏位置。

### HingePaneLayout：物理避让铰链

把内容拆分到铰链两侧，自动检测铰链方向：

- **垂直铰链**（`FoldAxis.vertical`）：使用 `Row`，左右分栏
- **水平铰链**（`FoldAxis.horizontal`）：使用 `Column`，上下分栏

```dart
HingePaneLayout(
  first: const CameraPanel(),     // 垂直铰链左侧 / 水平铰链上方
  second: const AlbumPanel(),     // 垂直铰链右侧 / 水平铰链下方
  fallback: const SinglePanel(),  // 必填：非折叠设备 / iOS / 嵌套面板走这里
  hingeMargin: 8,                 // 距铰链的安全间距
)
```

**走 `fallback` 的场景**：
- 无铰链（连续屏或非折叠设备）
- 嵌套在子面板中（本地尺寸 ≠ 窗口尺寸）
- 约束宽度/高度无界
- pane 尺寸计算后不合法（≤ 0）

### 示例页面

**文件**: `lib/features/_responsive_demo/presentation/pages/fold_aware_demo_page.dart`

从「响应式适配示例 → 折叠屏适配」进入。由于普通设备上 `FoldInfo` 恒为
`none`，页面提供**模拟铰链开关**（通过 `MediaQuery.copyWith` 注入虚拟
`DisplayFeature`），可在任何设备/模拟器上演示完整行为。
支持切换垂直/水平铰链方向。Android 折叠屏真机上关闭模拟即可观察系统真实数据。

---

## AppShellPage 自适应导航

**路径**: `lib/features/app/presentation/pages/app_shell.dart`

自动切换导航形式：

| 窗口宽度 | 导航形式 | 标签显示 |
|---------|---------|---------|
| < 600dp 或内容区过窄 | NavigationBar（底部） | 图标 + 标签 |
| 600-839dp | NavigationRail（左侧） | 图标 + 选中标签 |
| ≥ 840dp | NavigationRail（左侧） | 图标 + 所有标签 |

**内容区保护**：即使窗口宽度 ≥ 600dp，如果扣除 NavigationRail + 分隔线后的内容区宽度不足 400dp，也会回退到底部导航，避免内容被压缩。

标签显示策略通过 `LayoutSemantics.railLabelType(constraints)` 统一管理。

### iPhone Duo 适配

iPhone Duo 内屏（~951×669dp）触发 medium/expanded 布局。在横屏模式下，iOS
将状态栏和系统管理的 bar 合并到屏幕一侧的**垂直控件条带**（~84dp）。

Flutter 自绘的 Widget（`AppBar`、`NavigationBar`、`CupertinoTabBar`）不会被系统
整合到垂直条带中——这是 Flutter 框架级限制，系统只移动 `UINavigationController` /
`UITabBarController` 管理的原生 bar。`SafeArea` 会正确避开垂直条带区域。

### 添加新的导航目的地

修改 `_destinations` 列表和 `AutoTabsRouter.routes`：

```dart
// 1. 在 _destinations 中添加
static const _destinations = <({IconData icon, IconData selectedIcon, String label})>[
  (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  (icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),  // 新增
];

// 2. 在 AutoTabsRouter.routes 中添加对应路由
routes: const [
  ExampleListRoute(),
  ProfileRoute(),
  SearchRoute(),  // 新增
],
```

---

## 示例页面

项目包含 9 个响应式适配示例页面，可从 **Profile → Responsive Demo** 进入：

### 1. Dashboard 仪表盘

**文件**: `responsive_dashboard_page.dart`

| 手机 | 平板竖屏 | 平板横屏/桌面 |
|------|---------|------------|
| 单列卡片列表 | 2 列统计网格 + 动态列表 | 左侧主面板（65%）+ 右侧动态边栏（35%） |

**学习要点**：`AdaptiveLayoutBuilder` 三级回调、`GridView.count` + `shrinkWrap` 嵌套、`Row` + `Expanded(flex:)` 按比例分栏

### 2. Master-Detail 分栏

**文件**: `master_detail_page.dart`

| 手机 | 平板 |
|------|------|
| 列表页 → push 全屏详情页 | 左侧列表面板 + 右侧详情面板 |

**学习要点**：`AdaptiveLayoutBuilder` 切换、手机用 AutoRoute 导航、平板用 `setState` 切换右侧面板、`ContentConstraint` 限制阅读宽度、`LayoutSemantics.masterPaneRatio`

### 3. 响应式表单

**文件**: `responsive_form_page.dart`

| 手机 | 平板 |
|------|------|
| 全宽单列字段 | 居中卡片 + 关联字段双列排列 |

**学习要点**：`AdaptiveBuilder` 纯 Widget 版切换、`ContentConstraint` + `Card` 容器、关联字段 `Row` + `Expanded` 双列排列

### 4. 自适应网格画廊

**文件**: `responsive_gallery_page.dart`

| 手机 | 平板竖屏 | 平板横屏/桌面 |
|------|---------|------------|
| 2 列 | 3 列 | 4 列 |

**学习要点**：`ResponsiveBreakpoints.valueOf` 一行获取列数

### 5. 设置页分栏

**文件**: `responsive_settings_page.dart`

| 手机 | 平板 |
|------|------|
| 分组卡片列表 | 左侧分类导航菜单 + 右侧设置项面板 |

**学习要点**：与 Master-Detail 类似、`ContentConstraint` 限制宽度 + `Card` 分组

### 6. 图文详情页

**文件**: `responsive_article_page.dart`

| 手机 | 平板 |
|------|------|
| 图片在上 + 文字在下 | 左侧图片区 + 右侧文字内容 |

**学习要点**：`Column` ↔ `Row` 切换、`ContentConstraint` 限制阅读宽度、`Wrap` 标签流式布局

### 7. 登录页

**文件**: `responsive_login_page.dart`

| 手机 | 平板 |
|------|------|
| 全屏表单 | 左侧品牌展示区 + 右侧登录表单 |

**学习要点**：SaaS 经典登录布局、`flex` 比例在不同断点调整、`ConstrainedBox(maxWidth: 420)` 居中

### 8. 聊天对话

**文件**: `responsive_chat_page.dart`

| 手机 | 平板 |
|------|------|
| 联系人列表 → push 全屏对话页 | 左侧联系人列表 + 右侧对话窗口 |

**学习要点**：消息气泡、在线状态、底部输入框固定在键盘上方

### 9. 折叠屏适配

**文件**: `fold_aware_demo_page.dart`

| 普通设备 | 模拟铰链开启后 |
|---------|--------------|
| `FoldInfo` 为 none，`HingePaneLayout` 走 fallback | 完整演示折叠屏行为 |

**学习要点**：`FoldInfo` 读取折叠姿态、`FoldAwareBuilder` 断点 + 铰链对齐、`HingePaneLayout` 双轴支持、模拟铰链开关（支持垂直/水平切换）

---

## 最佳实践

### 1. 优先使用 AdaptiveBuilder / AdaptiveLayoutBuilder

```dart
// ✅ 最简洁：子组件不需要 constraints
AdaptiveBuilder(
  compact: MobileView(),
  medium: TabletView(),
)

// ✅ 子组件需要 constraints
AdaptiveLayoutBuilder(
  compact: (_) => MobileView(),
  medium: (c) => SplitView(masterWidth: c.maxWidth * 0.4),
)

// ✅ 连续计算（列数/间距）：直接用 LayoutBuilder
LayoutBuilder(
  builder: (context, c) {
    final columns = ResponsiveBreakpoints.valueOf(context, c, compactValue: 2, mediumValue: 3, expandedValue: 4);
    return GridView(crossAxisCount: columns);
  },
)

// ❌ 避免：使用全屏宽度判断局部布局
if (MediaQuery.sizeOf(context).width < 600) { ... }
```

### 2. 不要检测设备类型

```dart
// ❌ 不要这样做
if (Platform.isAndroid && isTabletDevice()) { ... }

// ✅ 基于可用空间
if (ResponsiveBreakpoints.isCompact(context, constraints)) { ... }
```

### 3. Token 选择

```dart
final tokens = ResponsiveTokens.of(context);

// ✅ 间距/尺寸：compact 真手机缩放，大屏固定 dp
padding: EdgeInsets.all(tokens.space(16, medium: 24, expanded: 32)),

// ✅ 字体：compact 真手机 sp 缩放，大屏固定 dp
fontSize: tokens.font(14, medium: 16),

// ✅ 主题/全局定义：不缩放
fontSize: tokens.fixedSize(16, medium: 20),

// ✅ 主题中不需要响应式缩放时，直接使用字面值
fontSize: 14,                        // 等价于 fixedSize(14) 但更简洁

// ✅ 平板端固定 dp（在 AdaptiveBuilder 的 medium/expanded 回调中）
padding: EdgeInsets.all(20),

// ✅ 布局结构用 Expanded/FractionallySizedBox
Row(children: [Expanded(flex: 35, child: list), Expanded(flex: 65, child: detail)])
```

### 4. 新增页面的适配策略

| 页面类型 | 最小适配（推荐所有页面） | 进阶适配（重要页面） |
|---------|:---:|:---:|
| 表单页 | `ContentConstraint(maxWidth: ResponsiveTokens.maxWidthForm)` | 双列字段布局 |
| 列表页 | `ContentConstraint(maxWidth: ResponsiveTokens.maxWidthList)` | 多列网格 / Master-Detail |
| 详情页 | `ContentConstraint(maxWidth: ResponsiveTokens.maxWidthDetail)` | — |
| Dashboard | — | 多面板 + 边栏 |

### 5. 页面布局变体的文件组织

当一个页面在手机和平板上有完全不同的 UI 设计时：

```
lib/features/xxx/presentation/pages/
├── xxx_page.dart                  # 入口（AdaptiveBuilder 分发）
├── layouts/
│   ├── xxx_compact_layout.dart    # 手机布局
│   └── xxx_tablet_layout.dart     # 平板布局
```

入口文件：

```dart
@RoutePage()
class XxxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      compact: const XxxCompactLayout(),
      medium: const XxxTabletLayout(),
    );
  }
}
```
