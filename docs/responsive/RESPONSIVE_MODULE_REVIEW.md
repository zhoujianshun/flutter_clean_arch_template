# 响应式模块代码评审（`lib/core/responsive/`）

> **已落实更新（2026-10-26）**
>
> 以下评审建议已在后续重构中落实，原文保留作为历史记录：
>
> | 评审项 | 落实情况 |
> |--------|---------|
> | P0-1：`ResponsivePolicy` 未接线 | 已重命名为 `BreakpointConfig`，所有断点方法读取其自定义阈值 |
> | P1-1：Token 旧 API 废弃 | `rsize/rfont/size/localSize/localFont` 及 `.rs/.rf/.s` 扩展已全部删除，统一为 `ResponsiveTokens.of(context).space/font/fixedSize` |
> | P1-3：静默回退无警告 | 旧 API 已删除，`ResponsiveTokens.of` 无 scope 时安全回退到窗口级判定 |
> | P2-2：窗口级 API 重复 | `ResponsiveContextX` 合并入 `breakpoints.dart`；`ResponsiveBreakpoints` 上的 `isXxxWindow` 保留（与 `isXxx` 约束版对称） |
> | 文件合并 | `responsive_context.dart` → `breakpoints.dart`；`constraints_scope.dart` → `adaptive_builder.dart`；模块从 8 文件缩减到 6 文件 |
> | `SCREENUTIL_GUIDE.md` | 已删除（内容被 `RESPONSIVE_COMPONENTS_API.md` 覆盖） |
>
> P0-2（`_coversWindow` 容差判定 + 分栏后清除子树铰链）、P0-3（明确「仅处理铰链」契约）、P1-2（`Expanded` 吸收浮点误差）已在第三轮修复中落实（见第 9 节）；P2-4（测试拆分）决策为保持单文件收敛，lint 已清零。

> 评审日期：2026-10-23（第二轮，基于工作区当前未提交代码）  
> 范围：`lib/core/responsive/` 全部 8 个文件、接入点 `main.dart` / `app_shell.dart` / `fold_aware_demo_page.dart`、`test/core/responsive/`。  
> 方法：静态审阅 + 调用点抽查 + `flutter analyze` + `flutter test`；参考 Flutter 3.47 官方自适应布局指南、Material 3 Window Size Class、`flutter_screenutil 5.9.3` 源码。未做真机折叠态验证。

## 1. 结论

**基线**：`flutter test test/core/responsive` 71 项全部通过；`flutter analyze lib/core/responsive test/core/responsive` 源码 0 问题、测试文件 19 条 lint（1 warning + 18 info）。

**总体评价**：模块方向正确——以 `LayoutBuilder` 约束为局部真值、`MediaQuery` 为窗口真值、`ResponsiveBreakpoints.resolve` 为唯一回退链、内容宽度上限替代整体缩放。上一轮评审的 P0（窗口/局部空间分离、`FoldAxis`、AppShell 最小内容宽度、`tryFromConstraints`、`ConstraintsScope` 异常信息、`outerPadding` 语义）已基本落地。

**本轮最需要处理的三件事**：

1. `ResponsivePolicy` 是一个**没有任何读取方**的配置对象——注入后断点不会变，属于"看起来可配置、实际硬编码"的 API 陷阱。
2. `HingePaneLayout` 的"全窗口"判定只比对宽/高相等，导致**在带 AppBar 的 Scaffold、NavigationRail 旁、Card 内等所有真实页面位置都走 fallback**（demo 页本身也是如此），水平铰链路径在实际应用中几乎不可达。
3. 折痕（`DisplayFeatureType.fold`）对齐分栏在文档和 demo 文案中被宣称支持，但实现只读取 `obstruction`（hinge），且 `foldCrease` 被标为 `@visibleForTesting`，**功能实际不可用**。

## 2. 上一轮建议的落实情况

| 上一轮建议 | 状态 | 备注 |
|---|---|---|
| 页面只用局部约束；窗口级 API 改名 `fromWindowSize` | ✅ | `breakpoints.dart`、`responsive_context.dart` 文档已明确边界 |
| AppShell 增加 `rail + divider + minContent` 复合条件 | ✅ | `app_shell.dart:101-110`，但阈值仍是类内常量，未进 Policy |
| `FoldAxis` + 统一 `HingePaneLayout(first/second)` | ✅ | 已替换 `HingeSplitLayout` |
| `FoldInfo` 保留特征列表、派生 `axis` | ✅ 部分 | 有 `features`/`axis`，缺 `panes`、`==`/`hashCode` |
| `FoldAwareBuilder` 非全窗口回退 `FoldInfo.none` | ✅ | 判定方式仍有缺陷，见 P0-2 |
| 引入可注入 `ResponsivePolicy` | ⚠️ 半成品 | 类已创建，**无人读取**，见 P0-1 |
| `tryFromConstraints` / debug 警告 | ✅ | assert 写法有瑕疵，见 P2-1 |
| `ConstraintsScope.of` 明确异常 | ✅ | |
| `ContentConstraint` padding 语义 + 断言 | ✅ | 改名 `outerPadding` |
| 删除/收紧 `StatefulAdaptiveBuilder` | ✅ | 已删除 |
| Token 收敛为 context-aware、替换裸 `.w/.h/.r/.sp` | ❌ 未做 | 见 P1-1 |

## 3. 做得好的地方

1. **单一回退真值**：`ResponsiveBreakpoints.resolve` 被 `valueOf`、`AdaptiveBuilder`、`FoldAwareBuilder`、`ResponsiveTokens._resolveByWindowClass` 共同委托，medium 缺失回退 compact 而非 expanded，测试已锁定。
2. **窗口 / 局部双轨 API 边界清晰**：`fromConstraints` vs `fromWindowSize`、`localSize` vs `rsize`，命名和文档都把"不要在页面内用窗口宽度"说清楚了。
3. **AppShell 的复合判定**是折叠屏外屏横持、分屏等场景的正确做法：断点到了 medium 但内容区 < 400dp 时仍退回底部导航。
4. `FoldInfo` 和 `BoxConstraints` 在同一个 `LayoutBuilder` 回调内读取，避免折叠↔展开过渡帧的状态撕裂。
5. `ContentConstraint` 用 `assert` 守住非法参数，`outerPadding` 命名直接说明了"在 `ConstrainedBox` 外"的语义。
6. 测试覆盖边界值、回退链、嵌套保护、垂直/水平铰链、`localSize` 大屏窄面板不缩放等核心语义，并把已知限制显式锁定。

## 4. 问题清单与修改方案

### P0-1：`ResponsivePolicy` 未接线，是"死配置"

**位置**：`breakpoints.dart:173-221`；读取方检索结果——`lib/` 内除定义文件外零引用。

`ResponsivePolicy` 暴露 `compactBreakpoint`、`expandedBreakpoint`、`minPaneWidth`、`navigationThreshold`，但：

- `ResponsiveBreakpoints.fromWidth / fromConstraints / fromWindowSize` 全部使用 `static const`；
- `AdaptiveBuilder`、`FoldAwareBuilder`、`ConstraintsScope` 不读取 Policy；
- `AppShell` 自己定义了 `_railWidth = 80`、`_minContentWidth = 400`，与 `minPaneWidth = 300`、`navigationThreshold = 600` 平行存在且语义不一致；
- `LayoutSemantics.masterPaneRatio` 的 `0.35 / 0.4` 同样硬编码。

按文档注入 `ResponsivePolicy(compactBreakpoint: 640)` 后，断点不会有任何变化。这比没有该类更糟：使用者会得到错误的"已生效"预期。`RESPONSIVE_COMPONENTS_API.md` 第 147 行起的章节也在描述一个不存在的行为。

**修改方案（二选一，推荐 A）**

A. 接线。把"按宽度分类"的职责挪到 Policy 上，静态常量只作默认值：

```dart
class ResponsivePolicy extends InheritedWidget {
  // ...字段不变

  /// 按宽度分类（唯一实现，ResponsiveBreakpoints.fromWidth 委托到默认实例）。
  WindowSizeClass classify(double width) {
    if (width >= expandedBreakpoint) return WindowSizeClass.expanded;
    if (width >= compactBreakpoint) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  WindowSizeClass? tryClassify(BoxConstraints c) =>
      c.hasBoundedWidth ? classify(c.maxWidth) : null;
}
```

- `AdaptiveBuilder` / `AdaptiveLayoutBuilder` / `FoldAwareBuilder` 在 `LayoutBuilder` 回调里用 `ResponsivePolicy.of(context).classify(constraints.maxWidth)`，并把 `policy` 一并放进 `ConstraintsScope`，子树里的 `localSize`、`LayoutSemantics` 直接读 `scope.policy`。
- `ResponsiveBreakpoints.fromWidth` 保留，内部委托 `const ResponsivePolicy(child: SizedBox.shrink()).classify(width)`，纯函数场景（Token、测试）仍可用。
- AppShell 的 `_minContentWidth` 改读 `policy.minPaneWidth`；`railWidth` 可作为 Policy 新字段或继续留在壳层（它是 Material 组件尺寸，不是产品策略）。
- 补测试：注入 `compactBreakpoint: 700` 后，650dp 必须判定 compact。

B. 删除。当前没有多品牌需求，按 YAGNI 删掉 `ResponsivePolicy` 和 API 文档章节，等真正需要时再加。

### P0-2：`HingePaneLayout` / `FoldAwareBuilder` 的"全窗口"判定使组件在真实页面中不可达

**位置**：`fold_aware.dart:174-176`（`isFullWindow`）、`fold_aware.dart:250-251`、`fold_aware.dart:265-266`；调用点 `fold_aware_demo_page.dart:253-265`、`333-358`。

当前逻辑：

```dart
if (constraints.maxWidth != windowSize.width) return fallback;   // 垂直铰链
if (constraints.maxHeight != windowSize.height) return fallback; // 水平铰链
```

问题：

1. **水平铰链路径在任何有 AppBar 的 `Scaffold.body` 中都失败**——body 高度 = 窗口高 − AppBar − 状态栏，永远不等于 `windowSize.height`。现有测试（`duo_layout_test.dart:446-483`）用无 AppBar 的 `Scaffold` + 890×890 `SizedBox` 才得以通过，并不代表真实页面。
2. **垂直铰链路径在 NavigationRail 旁、Card/Padding 内同样失败**。demo 页把 `HingePaneLayout` 放在 `Card > Padding(16)` 内，宽度必然 ≠ 窗口宽度，因此即使在真实 Galaxy Fold 上，demo 也只会显示 fallback，无法演示任何铰链能力。
3. 用 `==` 比较 double；在 DPR 非整数设备上，经过 `SafeArea` / `MediaQuery.removePadding` 后极易出现 `0.33dp` 级差异。
4. "是否全窗口"的逻辑在 `FoldAwareBuilder` 和 `HingePaneLayout` 各写一份，后者还按轴向写了两次。
5. 分栏成功后，没有向两个 pane 的子树移除铰链信息，子树内再出现 `FoldAwareBuilder` 会重新读取到同一个铰链（目前因宽度不匹配而回退，但这是碰巧而非设计）。

这与 Flutter 官方 `DisplayFeatureSubScreen` 的契约一致（它同样假定覆盖整屏），官方处理方式是**在覆盖整屏的位置分屏一次，然后用 `MediaQueryData.removeDisplayFeatures(subScreen)` 向子树声明"你所在的子屏幕没有铰链"**。本模块缺少后半步。

**修改方案**

1. **明确并执行"在壳层分屏"的使用契约**。`HingePaneLayout` 应放在覆盖整个窗口的位置（`MaterialApp.builder`、`AppShell` 的 `Scaffold` 之外、或 `extendBodyBehindAppBar` 的 body），由**每个 pane 自带 `Scaffold`/`AppBar`**。这是 `dual_screen` 包 `TwoPane` 的推荐用法，也是唯一不需要猜测偏移的方案。文档和 demo 都要按此改写；demo 页当前的两处嵌套用法应改为"全屏子页面"演示，或至少在文案中说明普通位置必然 fallback。
2. 分屏成功后，用 `MediaQuery.removeDisplayFeatures` 包裹每个 pane：

```dart
Widget _pane(BuildContext context, Rect paneRect, Widget child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.removeDisplayFeatures(paneRect),
    child: child,
  );
}
```

3. 把"是否覆盖窗口"抽成私有工具并使用容差，两处共用：

```dart
bool _coversWindow(BoxConstraints c, Size window, Axis axis) {
  final (local, global) = switch (axis) {
    Axis.horizontal => (c.hasBoundedWidth ? c.maxWidth : null, window.width),
    Axis.vertical => (c.hasBoundedHeight ? c.maxHeight : null, window.height),
  };
  return local != null && (local - global).abs() < precisionErrorTolerance;
}
```

4. 把 pane 计算从 widget 里挪到 `FoldInfo`，便于测试和复用（见 P0-3 的 `panesFor`）。
5. 补测试：`Scaffold(appBar: AppBar(), body: HingePaneLayout(...))` + 水平铰链，期望行为必须明确（当前是 fallback，若保持则写入文档；若改契约则期望分栏）。

### P0-3：折痕对齐分栏"宣称支持、实际不可用"

**位置**：`fold_aware.dart:31-32`（文档宣称）、`fold_aware.dart:92-98`（`@visibleForTesting`）、`fold_aware.dart:238`（只读 `obstruction`）、`fold_aware_demo_page.dart:249`（文案"分栏线优先对齐铰链/折痕左侧"）。

- `HingePaneLayout` 只处理 `fold.obstruction`，`DisplayFeatureType.fold` 一律 fallback；
- `foldCrease` / `obstruction` 两个 `Rect` 被标 `@visibleForTesting`，业务代码无法读取；但 `features` 又是公开的，调用方可以 `features.first.bounds` 绕过，注解形同虚设；
- `FoldInfo` 没有 `==`/`hashCode`/`toString`，`fold == FoldInfo.none` 对解析出的空实例为 false，调试打印只有 `Instance of 'FoldInfo'`。

**修改方案**

1. 决定折痕是否支持。考虑到 iOS 当前 `displayFeatures` 恒为空，建议**明确列为不支持**，删除代码注释、API 文档和 demo 文案中"按折痕对齐"的表述；或者以显式开关支持：

```dart
enum FoldSplitMode { hingeOnly, hingeOrCrease }

HingePaneLayout(splitMode: FoldSplitMode.hingeOrCrease, ...)
```

2. 收紧 `FoldInfo` 数据模型：去掉两个 `Rect` 上的 `@visibleForTesting`，改为由 `FoldInfo` 提供派生 pane 计算，widget 只负责摆放：

```dart
typedef FoldPanes = ({Rect first, Rect second, FoldAxis axis});

FoldPanes? panesFor(Size window, {double margin = 0, bool includeCrease = false}) {
  final bounds = includeCrease ? (obstruction ?? foldCrease) : obstruction;
  if (bounds == null || bounds.isEmpty && !includeCrease) return null;
  // 按 axis 计算两个 Rect，任一宽/高 <= 0 返回 null
}
```

3. 为 `FoldInfo` 实现 `==`、`hashCode`、`toString`（或改为 Freezed `abstract class`，与项目其余数据类一致）。

### P1-1：Token 体系仍以 `ScreenUtil` 单例为真值，全树重建 + 三套窗口宽度来源

**位置**：`responsive_tokens.dart:57-63`、`responsive_tokens.dart:236-245`；`main.dart:187-201`；`flutter_screenutil-5.9.3/lib/src/screenutil_init.dart:147-175`。

1. **三个窗口宽度真值源**：`MediaQuery.sizeOf(context)`（`fromWindowSize`）、`ScreenUtil().screenWidth`（`_globalWindowClass`）、`ConstraintsScope`（局部）。前两者当前数值一致，但没有机制保证（例如将来 `ScreenUtilInit` 放到 `MaterialApp.builder` 内、或测试里只配置其中一个）。
2. **无 `BuildContext` 的 Token 无法建立 Inherited 依赖**。`16.rs` 的正确刷新完全依赖 `ScreenUtilInit._revalidate` 在窗口尺寸变化时对**整棵 Element 树**逐个 `markNeedsBuild`（`_updateTree`）。折叠屏展开/合上、Android 分屏拖拽、桌面窗口缩放时，每一帧都会触发全树重建，这正是折叠屏适配最敏感的性能路径。
3. 测试必须先初始化 `ScreenUtil`，否则 `_globalWindowClass` 抛错，单元测试和 widget 测试被迫耦合第三方包。
4. 业务层仍大量直接使用 `.w/.h/.r/.sp`（`lib/shared/widgets/` 25 个文件、`lib/features/` 40 余个文件），绕过了 Token 的大屏保护，本模块的 clamp 策略只覆盖少数页面。
5. 命名与类型：`.rs/.rf/.s` 为缩写，违反项目 `flutter-official.mdc` 的"Avoid abbreviations"；`.s` 太短易与其他扩展冲突；`rsize(num compactValue, {double? medium})` 参数类型不一致。

**修改方案**

1. 新增唯一 context 入口，内部读 `MediaQuery.sizeOf` 建立精确依赖，`ScreenUtil` 退居 compact 字体缩放实现细节：

```dart
class ResponsiveTokens {
  static ResponsiveTokens of(BuildContext context) {
    final scope = ConstraintsScope.maybeOf(context);
    final windowClass = scope?.windowClass ??
        ResponsivePolicy.of(context).classify(MediaQuery.sizeOf(context).width);
    return ResponsiveTokens._(windowClass, isGloballyCompact: ...);
  }

  double space(double compact, {double? medium, double? expanded});
  double font(double compact, {double? medium, double? expanded});
}
```

2. `rsize/rfont/size` 及 `.rs/.rf/.s` 标记 `@Deprecated('Use ResponsiveTokens.of(context)')`，先停止新增再逐步迁移。
3. 把 `fontSizeResolver` 中"≥ 600dp 不缩放"的策略下沉到 `ResponsiveTokens`，避免 `main.dart` 与 Token 各维护一份断点逻辑。
4. 业务层 `.w/.h/.r/.sp` 的替换按上一轮顺序推进（共享按钮 → 登录/个人页 → demo），并用 `custom_lint` 或 `analysis_options` 的 `banned` 规则阻止新增。
5. 补充 100% / 150% / 200% 系统字体缩放下的 widget 测试；Token 不应替代 `MediaQuery.textScalerOf`。

### P1-2：`HingePaneLayout` 固定尺寸 `Row/Column` 存在浮点溢出风险

**位置**：`fold_aware.dart:257-263`、`fold_aware.dart:273-279`。

`firstWidth + (hinge.width + 2·margin) + secondWidth` 在数学上恰等于 `maxWidth`，但三个 double 相加可能大于 `maxWidth` 一个 ulp，触发黄黑溢出条。

**修改方案**：首段和铰链间隙用 `SizedBox`，末段用 `Expanded` 吸收误差：

```dart
Row(children: [
  SizedBox(width: firstWidth, child: first),
  SizedBox(width: hinge.width + hingeMargin * 2),
  Expanded(child: second),
])
```

并补一条 `maxWidth = 1079.9999` 之类的非整数宽度测试。

### P1-3：静默回退过多，误用无法被发现

**位置**：`responsive_tokens.dart:153-156`、`responsive_tokens.dart:179-182`（无 `ConstraintsScope` 回退全局）；`breakpoints.dart:43-56`（无界回退 compact）。

`localSize` 的设计初衷是"在 `AdaptiveBuilder` 子树内使用"，但缺少 Scope 时静默退回全局 `rsize`，和把 `rsize` 直接写错位置没有区别，页面在 NavigationRail 旁被过度放大时无法定位原因。

**修改方案**：与 `fromConstraints` 一致，在 debug 下输出一次性警告（用 `Set<String>` 记录调用栈/位置避免每帧刷屏），或提供 `localSizeOrNull`。

### P2-1：`fromConstraints` 的断言写法无效

**位置**：`breakpoints.dart:45-52`。

```dart
assert(() { debugPrint(...); return true; }(), 'Unbounded width should not be used ...');
```

闭包恒返回 `true`，第二个参数的消息永远不会出现；每次 build 都会 `debugPrint`，横向滚动列表中会刷屏。建议改为 `assert(() { if (!_warned) {...} return true; }())` 或直接 `FlutterError.reportError` 一次。

### P2-2：窗口级判定 API 三处重复

**位置**：`breakpoints.dart:86-99`、`responsive_context.dart:14-21`、`responsive_tokens.dart:57`。

`ResponsiveBreakpoints.isCompactWindow(context)` 与 `context.isCompactWindow` 完全等价。建议保留 `ResponsiveBreakpoints.fromWindowSize` 一个底层方法 + `ResponsiveContextX` 一组便捷 getter，删除 `ResponsiveBreakpoints` 上的三个 `isXxxWindow`。

### P2-3：`WindowSizeClass` 与 Material 3 现行规范的差距

**位置**：`breakpoints.dart:3-11`。

M3 当前 Window Size Class 为 compact / medium / expanded / **large (1200–1599)** / **extra-large (≥1600)**。手机 + 平板目标下三档足够，但注释应写明"采用前三档"，并在 P0-1 的 Policy 中预留扩展位（例如 `List<(double, WindowSizeClass)> thresholds`），避免未来加档时改动所有 `switch`。

### P2-4：测试组织与质量

**位置**：`test/core/responsive/duo_layout_test.dart`（1565 行，20 个 group）。

- 文件名 `duo_layout_test.dart` 已不能反映内容（覆盖整个模块），建议按源文件拆分：`breakpoints_test.dart`、`adaptive_builder_test.dart`、`fold_aware_test.dart`、`responsive_tokens_test.dart`、`app_shell_test.dart`。
- `flutter analyze` 19 条：`unused_local_variable`（374 行）、`prefer_const_constructors` ×5、`unnecessary_underscores` ×12、`avoid_redundant_argument_values` ×1。
- "外屏横持断点行为锁定"组锁定的是已知限制而非期望行为，建议改为 `skip: '待 P0-1 Policy 接线后改为 SafeArea 感知判定'`，或在 AppShell 层写期望行为的测试（678dp 窗口 + 84dp 侧栏 → 底部导航）。
- 缺失用例：带 AppBar 的水平铰链、非整数宽度溢出、`ResponsivePolicy` 注入生效、200% 文字缩放、`MediaQuery.removeDisplayFeatures` 后子树不再读到铰链。

### P2-5：文档与代码不一致

- `docs/README.md:118` 链接到 `RESPONSIVE_CODE_REVIEW.md`，该文件不存在（实际为本文件）。
- `RESPONSIVE_COMPONENTS_API.md` §ResponsivePolicy 描述了未生效的能力（P0-1）。
- `fold_aware.dart:31-32` 与 demo 文案宣称折痕对齐（P0-3）。
- `fold_aware_demo_page.dart` 两处 `HingePaneLayout` 位于 Card 内，真机上也只能看到 fallback（P0-2）。

## 5. 逐文件速评

| 文件 | 行数 | 评价 | 关联问题 |
|---|---|---|---|
| `breakpoints.dart` | 221 | 核心职责清晰；`ResponsivePolicy` 未接线；断言写法无效；窗口级 bool 重复 | P0-1, P2-1, P2-2, P2-3 |
| `adaptive_builder.dart` | 128 | 简洁正确，两类构建器职责分明 | 需在 P0-1 后读取 Policy |
| `constraints_scope.dart` | 73 | 良好；错误信息友好 | 建议增加 `policy` 字段 |
| `content_constraint.dart` | 62 | 良好；断言 + 命名清晰 | 无 |
| `fold_aware.dart` | 284 | 方向正确但契约执行不严；三处 `==` 比较；缺 `removeDisplayFeatures` | P0-2, P0-3, P1-2 |
| `layout_semantics.dart` | 24 | 过薄，常量硬编码 | 并入 Policy 或扩充 |
| `responsive_context.dart` | 40 | `hasAsymmetricHorizontalPadding` 实用；窗口 getter 重复 | P2-2 |
| `responsive_tokens.dart` | 245 | 文档详尽，但真值源与重建机制依赖 ScreenUtil | P1-1, P1-3 |

## 6. 推荐实施顺序

| 阶段 | 工作项 | 验收标准 |
|---|---|---|
| 1 | P0-1：接线或删除 `ResponsivePolicy`；AppShell/LayoutSemantics 常量入 Policy | 注入 `compactBreakpoint: 700` 后 650dp 判定 compact 的测试通过；文档与行为一致 |
| 2 | P0-2 + P1-2：抽 `_coversWindow` 容差判定、`removeDisplayFeatures`、`Expanded` 收尾、demo 改为全屏演示 | 带 AppBar 的水平铰链用例行为明确；非整数宽度无溢出；子树读不到铰链 |
| 3 | P0-3：折痕支持要么显式开关要么删除宣称；`FoldInfo` 补 `==`/`toString`/`panesFor` | API 文档、代码注释、demo 文案三者一致 |
| 4 | P1-1 + P1-3：`ResponsiveTokens.of(context)`；旧 API `@Deprecated`；静默回退加警告 | 新代码无 `.rs/.rf/.s`；测试不再初始化 ScreenUtil 即可运行 Token 用例 |
| 5 | P2-x：断言修正、API 去重、测试拆分、README 断链修复、lint 清零 | `flutter analyze` 0 问题；README 链接全部可达 |

## 7. 建议测试矩阵（增补项）

| 场景 | 必测点 |
|---|---|
| `ResponsivePolicy` 注入 | 自定义阈值对 `AdaptiveBuilder`、`localSize`、AppShell 全部生效 |
| 水平铰链 + AppBar | `Scaffold(appBar, body: HingePaneLayout)` 的行为与文档一致 |
| 非整数窗口宽度 | `1079.9999 × 800` 下 `HingePaneLayout` 无溢出 |
| 子屏幕隔离 | pane 内 `FoldInfo.fromContext` 返回无铰链 |
| 窗口缩放性能 | 桌面/分屏连续拖拽 300 帧，统计 rebuild 次数（迁移 Token 前后对比） |
| 文字缩放 | 200% 下登录页、设置页无溢出，可点击区域 ≥ 48dp |

## 8. 参考

- Flutter 官方：Adaptive & responsive design — "Use `LayoutBuilder` for local constraints, `MediaQuery.sizeOf` for window"；`DisplayFeatureSubScreen`、`MediaQueryData.removeDisplayFeatures`。
- Material 3：Window size classes（compact / medium / expanded / large / extra-large）。
- `flutter_screenutil 5.9.3`：`ScreenUtilInit._revalidate` / `_updateTree` 全树重建实现。
- Microsoft `dual_screen` 包 `TwoPane`：铰链分屏组件应位于屏幕根部、每个 pane 自带 `Scaffold`。

## 9. 第三轮修复记录（2026-10-26）

本轮针对第三轮 code review 发现的问题完成如下修复，全部通过 `flutter analyze` 与 `duo_layout_test.dart` 回归验证：

| 问题 | 严重度 | 修复内容 |
|---|---|---|
| Token 层 ScreenUtil 单例硬依赖 | 中 | `space()` 的 compact 缩放改用窗口级 MediaQuery 宽度（与 `ScreenUtil().screenWidth` 同源等价，`scaleWidth` 不受 `splitScreenMode`/`minTextAdapt` 影响）；`font()` 保留 `setSp`（维持根部 `fontSizeResolver` 语义）但增加 `_setSpSafe` 守卫——未接线 `ScreenUtilInit` 时回退固定 dp 并按调用点去重输出一次性 debug 警告，不再抛 `LateInitializationError` |
| `FoldAwareBuilder` 嵌套保护仅校验水平轴 | 低 | 改为按铰链轴向匹配校验：垂直铰链要求宽度覆盖完整窗口，水平铰链要求高度覆盖（与 `HingePaneLayout` 分栏逻辑对齐）。修复水平铰链下全宽半高组件误用全局坐标的缺口，同时不再误伤带 AppBar/bottomNavigationBar 的 Scaffold body |
| `BreakpointConfig` 无阈值倒置校验 | 低 | const 构造器追加 `assert(compactBreakpoint < expandedBreakpoint)`，debug 期即捕获接线错误 |
| `ConstraintsScope.updateShouldNotify` 意图不明 | 低 | 补充 doc comment 说明刻意全量比较 constraints 的原因，防止被误"优化"为仅比较宽度 |
| `FoldInfo.hashCode` 与 `==` 不对称 | 极低 | hash 纳入 `Object.hashAll(features)`，与 `listEquals(features)` 的相等语义对齐 |
| `ContentConstraint.outerPadding` 文档公式不准 | 低 | 修正为精确公式 `outerPadding.horizontal + min(maxWidth, parentWidth - outerPadding.horizontal)`，恒 ≤ parentWidth |

测试增补：`space` 无 ScreenUtilInit 可用、`font` 未初始化回退与初始化缩放三例；轴向保护三例（垂直铰链全宽半高传递、水平铰链全宽半高降级、水平铰链全高半宽传递）；倒置阈值断言一例。
