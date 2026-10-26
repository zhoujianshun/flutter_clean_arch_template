# 平板适配 — 架构决策记录（ADR）

本文档记录项目平板适配过程中的关键架构决策及其背景。

> **实现细节和 API 用法请参考** [`RESPONSIVE_COMPONENTS_API.md`](./RESPONSIVE_COMPONENTS_API.md)

---

## ADR-1: 单 App 渐进增强 vs. Monorepo 双 App

**决策**: 单 App + 渐进式增强

**背景**: 考虑过 Monorepo 方案（手机和平板各一个 App），共享 domain/data 层，各自维护 presentation 层。

**选择理由**:
- 折叠屏设备展开/折叠时窗口宽度连续变化，单 App + `LayoutBuilder` 可实时切换布局，双 App 无法处理
- 应用商店只需管理一个应用，用户只需安装一次
- 不增加 CI/CD 复杂度
- `AdaptiveBuilder` + `LayoutBuilder` 的组合已足够满足布局变体需求

**否决方案的适用场景**: 手机和平板功能完全不同（如手机端只读、平板端可编辑），且不需要考虑折叠屏

---

## ADR-2: 断点对齐 Material 3 Window Size Classes

**决策**: 使用 Material 3 标准断点 — Compact(600dp)、Medium(600-839dp)、Expanded(840dp+)

**背景**: 自定义断点（如 480/768/1024）会导致与 Material 3 组件（NavigationRail 等）的切换点不一致。

**选择理由**:
- 与 Material 3 组件的内置断点保持一致
- 与 Flutter 官方 `adaptive_scaffold` 和社区方案的断点定义一致
- 600dp 恰好覆盖大部分折叠屏展开宽度

**实现**: `ResponsiveBreakpoints.compact = 600`、`ResponsiveBreakpoints.expanded = 840`，所有工具类和组件统一引用这两个常量

---

## ADR-3: 基于可用空间而非设备类型做布局决策

**决策**: 使用 `LayoutBuilder` 的 `constraints.maxWidth`，而非 `Platform.isAndroid + shortestSide` 检测设备类型

**背景**: 检测设备类型（手机/平板）的方式无法正确处理折叠屏、分屏和桌面窗口调整等场景。

**选择理由**:
- 折叠屏展开后宽度为 "平板级"，但 `Platform` 仍认为是手机
- iPadOS 的 Stage Manager 允许自由调整窗口大小
- Android 的分屏模式会把平板空间缩小到 "手机级"
- 基于可用空间的方案天然支持所有这些场景

---

## ADR-4: ScreenUtil 单 designSize + fontSizeResolver 补偿

**决策**: 全局保持手机 designSize (375×812)，通过 `fontSizeResolver` 在平板上限制字体缩放

**背景**: 考虑过运行时动态切换 designSize（手机用 375、平板用 768），但 ScreenUtil 在 Widget 树根部初始化，切换会导致所有 `.w` 值含义瞬间改变。

**选择理由**:
- 手机端（< 600dp）`.w` / `.sp` 行为不变，零迁移成本
- 平板端字体通过 `fontSizeResolver` 返回原始 dp 值（不再按宽度等比放大）
- 平板端间距在 `AdaptiveBuilder` 的 medium/expanded 回调中直接用 dp，不经过 ScreenUtil
- 折叠屏切换时无 UI 跳变

**替代方案**: `ResponsiveTokens.of(context).space()` / `.font()` 按断点返回固定 dp 值，平板端不缩放

---

## ADR-5: 不引入 responsive_framework 等第三方响应式包

**决策**: 使用项目自定义的轻量响应式工具（`ResponsiveBreakpoints` + `ResponsiveTokens` + `AdaptiveBuilder`）

**背景**: 评估了 `responsive_framework`（v1.5.1、700+ stars）包。

**选择理由**:
- `responsive_framework` 的全局缩放策略与 ScreenUtil 的精细控制在理念上冲突——两者同时使用会产生 "双重缩放" 问题
- 它的 `ResponsiveBreakpoints.of(context)` 使用 `InheritedWidget`，仅响应屏幕宽度，不支持 `LayoutBuilder` 约束
- 项目需要 LayoutBuilder 约束（折叠屏/分屏），该包不满足
- 自定义方案仅 4 个文件 ~300 行代码，维护成本极低
- 作为模板项目，减少外部依赖有助于使用者理解底层原理

**详细对比**: 参见 [`RESPONSIVE_BEST_PRACTICES_COMPARISON.md`](./RESPONSIVE_BEST_PRACTICES_COMPARISON.md)

---

## ADR-6: 模块化响应式工具架构

**决策**: 将响应式工具拆分为 4 个独立模块，替代原先的单一 `ResponsiveUtils` 文件

**背景**: 初始实现将所有断点、设计 Token、语义决策集中在 `ResponsiveUtils` 一个文件中，随着功能增长，职责过于庞杂。

**最终结构**:

| 文件 | 路径 | 职责 | 说明 |
|------|------|------|------|
| `breakpoints.dart` | `core/responsive/` | 断点判定 | 单一真值源，定义常量 + 提供 `isCompact`/`valueOf` 等方法 |
| `responsive_tokens.dart` | `core/responsive/` | 设计 Token | 设计稿尺寸、内容宽度常量、`ResponsiveTokens.of(context).space/font/fixedSize` |
| `adaptive_builder.dart` | `core/responsive/` | 声明式组件 + 约束作用域 | `AdaptiveBuilder` / `AdaptiveLayoutBuilder` / `ConstraintsScope` |
| `layout_semantics.dart` | `core/responsive/` | 语义决策 | `railLabelType()`、`masterPaneRatio()` 等页面层布局语义 |
| `content_constraint.dart` | `core/responsive/` | 内容约束 | 大屏上限制内容最大宽度并居中 |
| `breakpoints.dart` | `core/responsive/` | 断点判定 + Context 扩展 | `ResponsiveBreakpoints`、`BreakpointConfig`、`ResponsiveContextX` |

**选择理由**:
- 单一职责：每个文件只做一件事
- 按需导入：页面只引用需要的模块
- 独立演进：修改断点值不影响缩放逻辑，反之亦然
- 正确的依赖方向：整个响应式模块（常量、Token、组件）统一收敛到 `core/responsive/`，
  避免 `core/` → `shared/` 的反向依赖；`shared/widgets` 组件按需引用 `core/responsive`

---

## ADR-7: StatefulAdaptiveBuilder 用 IndexedStack 保持状态

**决策**: 提供 `StatefulAdaptiveBuilder`，使用 `IndexedStack` 在断点切换时保持子组件状态

**背景**: `AdaptiveBuilder` 在断点切换时销毁旧子树、创建新子树——表单输入和滚动位置会丢失。

**选择理由**:
- 平板旋转（竖屏 ↔ 横屏）是高频操作，表单丢失数据体验极差
- `IndexedStack` 是 Flutter 原生方案，简单可靠
- 默认 `AdaptiveBuilder` 仍然是轻量版（不持有多份子组件），`StatefulAdaptiveBuilder` 仅在需要时使用

**权衡**: 所有断点的子组件同时存在于内存中，不适合包含大量重资源（如视频播放器）的页面

---

## ADR-8: 折叠屏 / iPhone Duo 适配策略

**决策**: 在既有约束驱动架构上补齐三项折叠屏能力，不做设备特判

**背景**: 2026 年 9 月 iPhone Duo 发布（折叠外屏 5.4"、展开内屏 7.6"），加上既有 Android 折叠屏，多形态设备成为必须覆盖的目标。Duo 展开态逻辑尺寸 **951 × 669**（14.2:10，宽大于高），恰好落入 expanded（≥ 840）；折叠外屏 466pt、展开竖持 669pt 分别对应 compact / medium——现有断点体系天然覆盖，无需调整。

**关键风险与对策**:

| 风险 | 对策 |
|------|------|
| iPhone Duo 内屏忽略方向锁定，运行时 `setPreferredOrientations` 导致 Flutter 引擎旋转状态冲突 | 完全移除运行时方向锁定（`OrientationPolicyWidget` 已删除）。iOS 方向由 `Info.plist` 静态声明；Android 不做方向锁定。全部依赖响应式 UI 自适应。 |
| 折叠→展开是 compact→expanded **跨级跳变**（466→951，跳过 medium） | `AdaptiveBuilder` 回退链（expanded→medium→compact）已覆盖；测试矩阵新增跨级跳变用例 |
| 展开态 `.w` 缩放 2.37× 视觉爆炸 | 业务组件统一使用 `ResponsiveTokens.of(context).space/font`（compact 缩放上限 clamp 0.85–1.15，大屏固定 dp）；demo 页面除外（可编译剔除） |
| Android 铰链设备交互元素压铰链 | 新增 `fold_aware.dart`：`FoldInfo` / `FoldAwareBuilder` / `HingePaneLayout` |
| 展开态横持（951×669）纵向空间有限 | `ContentConstraint` 新增可选 `maxHeight` 参数 |
| iPhone Duo 内屏横屏，系统将 bar 合并到侧边垂直控件条带，Flutter 自绘 bar 无法整合 | Flutter 框架级限制。`SafeArea` 正确避开垂直条带（~84dp）。添加 `hasAsymmetricHorizontalPadding` 辅助属性；布局根据宽度断点决策而非 `orientation`。`ConstraintsScope` 让子组件读取局部约束。未来可评估 `nitro_fold_duo` / `iphone_duo_layout` 插件。 |

**组件选型决策**（详见 [`RESPONSIVE_COMPONENTS_API.md` 折叠屏章节](./RESPONSIVE_COMPONENTS_API.md#折叠屏适配foldinfo--foldawarebuilder--hingesplitlayout)）：

- **一般页面**只需 `AdaptiveBuilder`——折叠/展开本质是宽度变化，断点体系天然覆盖
- `FoldAwareBuilder` 仅用于**分栏线需对齐铰链/折痕**的两栏布局
- `HingeSplitLayout` 仅用于**交互元素必须物理避让铰链遮挡**的场景，`fallback` 必填且须完整可用
- `displayFeatures` 只在 Android 填充；iPhone Duo 上 `FoldInfo` 恒为 `none`，完全依赖断点体系兜底

**变更文件**:
- 新增 `core/responsive/fold_aware.dart`（`FoldInfo.fromContext` 读 `MediaQuery.displayFeaturesOf`，解析出 `obstruction`（铰链遮挡）/ `foldCrease`（折痕）/ `isHalfOpened`（半开姿态）；`FoldAwareBuilder` 组合断点+姿态；`HingeSplitLayout` 按铰链拆分左右两栏并物理避让）。对话框避铰链直接用官方 `DisplayFeatureSubScreen`。

**测试矩阵**: `test/core/responsive/duo_layout_test.dart` 覆盖 Duo 三形态（466 / 669 / 951）断点判定、跨级回退、Token clamp、FoldInfo 解析。

**iPhone Duo 特性说明**:
- 连续内屏 + 极小折痕，iOS 不向 Flutter 报告 `displayFeatures`——`FoldInfo.obstruction` 恒为 null，分栏线按比例兜底（`hingeBounds ?? maxWidth * 0.4`）
- 内屏忽略 `supportedInterfaceOrientations`（Apple 平台行为），运行时调用 `setPreferredOrientations` 会导致 Flutter 引擎旋转状态冲突——已通过移除运行时方向锁定解决
- 内屏横屏时系统将 status bar、navigation bar 等合并到侧边垂直控件条带（~84dp），Flutter 自绘的 `AppBar`/`NavigationBar` 不受系统管理，无法整合——这是 Flutter 框架级限制
- `LaunchScreen.storyboard` 需使用 Safe Area Layout Guide + `useTraitCollections`/`useSafeAreas` 声明，否则 iOS 以兼容模式运行 App

---

## 决策时间线

| 日期 | 决策 | 要点 |
|------|------|------|
| 初始阶段 | ADR-1, ADR-2, ADR-3 | 确定单 App + M3 断点 + 可用空间方案 |
| 基础建设 | ADR-4 | ScreenUtil 单 designSize 策略 |
| 工具评估 | ADR-5 | 评估并否决 responsive_framework |
| 重构优化 | ADR-6, ADR-7 | 模块化拆分 + 有状态构建器 |
| 折叠屏时代 | ADR-8 | 折叠屏 / iPhone Duo 适配策略 |
