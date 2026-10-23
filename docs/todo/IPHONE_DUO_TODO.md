# iPhone Duo 适配 TODO

> 记录 iPhone Duo（折叠屏 iPhone）适配中已识别但尚未完成的工作项。
>
> 背景：iPhone Duo 内屏（~951×669dp）在横屏模式下，iOS 将系统管理的 bar
> 合并到右侧 ~84dp 的**垂直控件条带（Vertical Controls）**。Flutter 自绘的
> `AppBar`/`NavigationBar`/`CupertinoTabBar` 不受系统管理，无法被整合到条带中
> ——这是 Flutter 框架级限制。

---

## P0 — 必须完成

### 1. 逐页验证横屏布局

- [ ] 在 iPhone Duo 模拟器（内屏横屏 ~951×669dp）上逐页检查所有功能页面
- [ ] 确认 `SafeArea` 正确避开右侧 84dp 垂直控件条带
- [ ] 确认无内容被垂直条带遮挡（特别是右对齐按钮、FAB、弹窗等）
- [ ] 检查内屏竖屏模式（~669×951dp）下 AppBar 高度是否合理（系统会预留较大顶部区域）

### 2. 非对称 padding 处理

- [ ] 排查项目中使用 `EdgeInsets.symmetric(horizontal: ...)` 且基于 `MediaQuery.padding` 构建间距的场景
- [ ] iPhone Duo 内屏横屏时 `padding = EdgeInsets(0, 0, 84, 34)`（左=0, 右=84），对称写法会导致一侧过宽
- [ ] 已提供辅助属性 `context.hasAsymmetricHorizontalPadding`，但**尚未在任何页面中实际使用**

### 3. 导航栏与垂直条带的交互

- [ ] **内屏横持**：`AppShellPage` 在 medium/expanded 布局下使用左侧 `NavigationRail`，但右侧有系统垂直条带，实际可用区域约 `951 - 84 = 867dp`
- [ ] 验证 NavigationRail + 内容区的比例是否合理
- [ ] 考虑横屏时是否需要调整 `masterPaneRatio` 等布局语义
- [ ] **外屏竖持**：判为 compact，用底部 `MyBottomNavigationBar`。如果此时也有 side inset，`Scaffold.bottomNavigationBar` 内容可能与垂直条带重叠——需真机验证
- [ ] **外屏横持**：完整窗口宽 678 ≥ 600 → 判为 medium（已知限制），SafeArea 可用宽仅 594。NavigationRail 会占去 ~80pt，内容区仅剩 ~514pt，且右侧叠 84pt 垂直条带。待 Flutter 官方明确「断点是否应扣 SafeArea inset」后再调整

---

## P1 — 建议完成

### 4. `hasAsymmetricHorizontalPadding` 实际集成

- [ ] 在需要精细 padding 控制的页面使用 `context.hasAsymmetricHorizontalPadding`
- [ ] 添加对应的 widget test 覆盖该属性的行为
- ~~`isWideScreenLandscape` 已移除~~ — 布局决策应基于宽度断点而非 orientation（最佳实践）

### 5. iOS SDK 升级路径评估

- [ ] 当前 Xcode / Flutter 使用的 iOS SDK 版本确认
  - iOS 26 SDK → App 以居中/等比缩放模式运行在 iPhone Duo 上
  - iOS 27 SDK → App 填充大部分显示区域
  - **iOS 27.1 SDK** → App 全屏 + 系统启用垂直控件条带
- [ ] 升级到 iOS 27.1 SDK 后需重新测试所有布局

### 6. 评估社区插件

- [ ] [`nitro_fold_duo`](https://pub.dev/packages/nitro_fold_duo) — 提供 `DuoBarScaffold`，将 Flutter 的 AppBar/TabBar 桥接到 iOS 原生垂直条带
- [ ] [`iphone_duo_layout`](https://pub.dev/packages/iphone_duo_layout) — 提供 `NativeToolbarHost`，通过 Platform Channel 委托原生 bar 渲染
- [ ] [`foldable`](https://pub.dev/packages/foldable) — `FoldAwareBuilder` + iOS size classes + 铰链角度流。⚠️ **与本项目 `FoldAwareBuilder` 同名**，引入时需用 `show`/`hide` 或前缀避免命名冲突。其 `bridgeMode` 默认 `none`，开启后 `DisplayFeatureSubScreen` 会把对话框/底部弹窗分裂到 ~455pt，本项目 `HingeSplitLayout` 只处理 `hinge` 不处理 `fold`，恰好规避此坑
- [ ] [`adaptive_platform_ui`](https://pub.dev/packages/adaptive_platform_ui) — 基于 foldable，将 toolbar/tab bar 移入侧边 Liquid Glass capsule
- [ ] `dual_screen_hinge` — 铰链角度/posture + `reservedRegions`
- [ ] `iphone_duo_ui_pro` — `DuoDisplayFeatures` 将 fold 重发布为 `DisplayFeature`（需 `DUO_SDK_27_1` flag）
- [ ] 以上插件均为预发布版本（0.x），需 iOS 27.1 SDK，待稳定版后重新评估

---

## P2 — 可选优化

### 7. 横屏专用布局优化

- [ ] iPhone Duo 内屏横屏有效区域约 867×669dp，接近平板尺寸
- [ ] 列表/详情页面可考虑主从分栏布局（`HingeSplitLayout` 或自定义 `Row + Expanded`）
- [ ] 表单页面可在横屏时采用双列布局

### 8. LaunchScreen 适配验证

- [ ] `LaunchScreen.storyboard` 已更新为 Safe Area Layout Guide 格式
- [ ] 验证 iPhone Duo 内屏展开启动时的过渡动画是否流畅
- [ ] 验证系统背景色 `systemBackgroundColor` 在深色模式下是否匹配 App 主题

### 9. 真机测试

- [ ] 模拟器无法完全模拟折叠/展开的物理过渡和传感器行为
- [ ] 获取 iPhone Duo 真机后进行端到端测试
- [ ] 重点关注：折叠↔展开过渡动画、横竖屏切换时的状态保持、垂直条带交互

---

## 已完成 ✅

- [x] 移除 `OrientationPolicyWidget`（运行时方向锁定导致 iPhone Duo 内屏状态冲突）
- [x] `Info.plist` 添加 iPhone landscape 方向支持
- [x] `LaunchScreen.storyboard` 现代化（Safe Area + `useSafeAreas`/`useTraitCollections`）
- [x] `responsive_context.dart` 新增 `hasAsymmetricHorizontalPadding`
- [x] `responsive_context.dart` 移除 `isWideScreenLandscape`（布局应基于宽度断点而非 orientation）
- [x] `app_shell.dart` 添加 iPhone Duo 适配文档注释
- [x] 模块拆分：`breakpoints.dart` / `responsive_tokens.dart` 移至 `core/responsive/`
- [x] 模块合并：`shared/responsive/` 全部收敛到 `core/responsive/`（消除 core→shared 反向依赖）
- [x] `adaptive_builder.dart` 迁移补漏：此前遗漏在 `shared/responsive/`，现已删除并让 git 识别为 rename 到 `core/responsive/`
- [x] 更新所有相关文档（RESPONSIVE_COMPONENTS_API / TABLET_ADAPTATION_GUIDE / SCREENUTIL_GUIDE / BEST_PRACTICES_COMPARISON）
- [x] 新增 `ConstraintsScope` InheritedWidget：AdaptiveBuilder 自动注入局部约束到子树
- [x] `ResponsiveTokens` 新增 `localSize` / `localFont`：基于局部约束的 context-aware 尺寸方法
- [x] 新增 `MyBottomNavigationBar`：平台自适应导航栏封装（CupertinoTabBar / Material NavigationBar）
- [x] `app_shell.dart` 使用 `MyBottomNavigationBar`、移除 `dart:io` + `Platform.isIOS`，改用 `defaultTargetPlatform`
- [x] 新增 ConstraintsScope / localSize 测试用例
- [x] **P0-1**：修复 `size/font/rsize/rfont` medium 回退 Bug — 收敛到 `_resolveByWindowClass` 单一回退源
- [x] **P0-2**：修复 `localSize/localFont` compact 缩放语义 — 大屏窄面板不缩放（路径 C）
- [x] 补充测试：P0 回归测试 + localFont + LayoutSemantics + hasAsymmetricHorizontalPadding + MyBottomNavigationBar（54 项全通过）
- [x] 同步 `RESPONSIVE_BEST_PRACTICES_COMPARISON.md` 中过时的 `fontSizeResolver` 代码片段
- [x] 添加 iPhone Duo 尺寸对照表（完整屏幕 vs SafeArea 可用宽度）

---

*最后更新：2026-10-21*
