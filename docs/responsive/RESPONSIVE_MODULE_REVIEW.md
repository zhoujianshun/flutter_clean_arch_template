# 响应式模块代码评审与改造方案

> 评审日期：2026-10-23  
> 范围：`lib/core/responsive/`、核心接入点及现有响应式测试。  
> 方法：静态代码审阅、调用点抽查、既有测试执行；未进行真机折叠态验证。

## 结论

模块已具备可用的基础架构：断点集中管理、优先使用 `LayoutBuilder`、内容最大宽度约束、局部约束传递以及折叠特征读取，普通手机、平板和大多数窗口缩放场景可以工作。

不过，它还不满足“复杂折叠屏和分屏场景可无条件复用”的最佳实践。最高优先级是统一**实际可用空间**的计算，并重构折叠铰链的坐标与方向模型；否则在带安全区、横向外屏、半开态或嵌套面板中，布局可能选择错误的导航形态或把分栏线放到错误位置。

本次基线验证执行 `flutter test test/core/responsive/duo_layout_test.dart`，64 项通过。该结果仅证明现有行为被测试锁定，不表示下列已识别限制已经解决。

## 做得好的地方

1. `ResponsiveBreakpoints.resolve` 将三档回退链收敛为单一真值，避免不同组件出现不一致的 `expanded → medium → compact` 降级规则。
2. `AdaptiveBuilder`、`AdaptiveLayoutBuilder` 和 `ConstraintsScope` 以父约束而非设备型号作局部布局决策，方向正确，适合分屏和导航栏旁的内容区。
3. `ContentConstraint` 为表单、列表和详情设置阅读宽度上限，避免大屏直接拉满；这比仅按设计稿整体缩放更符合 Flutter 自适应布局理念。
4. `FoldInfo` 区分物理铰链（`hinge`）和非遮挡折痕（`fold`），`HingeSplitLayout` 也已经对无铰链、无界宽度及明显嵌套场景做了保守回退。
5. 测试覆盖了边界断点、回退语义、局部 Token、铰链左右分栏、内容约束和状态保持的基础行为，明显优于常见的“仅用模拟器目测”方案。

## 发现与修改方案

### P0：断点使用的是窗口宽度，未统一为实际可用空间

**位置**：`lib/core/responsive/breakpoints.dart:38`、`lib/core/responsive/responsive_tokens.dart:42`、`lib/features/app/presentation/pages/app_shell.dart:89`、`test/core/responsive/duo_layout_test.dart:1442`。

`fromContext` 直接读取 `MediaQuery.sizeOf(context).width`，全局 Token 则读取 `ScreenUtil().screenWidth`。两者都不表示 SafeArea、系统侧边区域、导航栏和父面板扣除后的真实内容宽度。现有测试已经明确锁定了“完整宽度 678dp 判为 medium、但 SafeArea 仅约 594dp”的已知限制；此时应用壳切换到 `NavigationRail` 后，内容区会进一步变窄。

**建议改造：**

1. 页面和组件布局一律只根据最近 `LayoutBuilder` 的有界 `BoxConstraints` 判定；不要在页面内使用 `fromContext` / `screenValueOf` 作布局分支。
2. 为导航壳新增“内容最小宽度”策略，例如同时满足 `railWidth + divider + minContentWidth` 才从底部导航切到 `NavigationRail`，而不是只判断根窗口是否达到 600dp。
3. 为确有全局需求的 API 明确命名为 `fromWindowSize`，并将其限制为窗口级策略；不要将其描述为“全局导航取决于物理屏幕”。
4. 将 SafeArea、键盘、系统侧栏与铰链占用后的区域作为集成测试输入，替换目前的“已知限制”回归测试。

### P0：`FoldAwareBuilder` 向局部布局暴露了全局坐标的折叠区域

**位置**：`lib/core/responsive/fold_aware.dart:37`、`lib/core/responsive/fold_aware.dart:130`、`lib/core/responsive/fold_aware.dart:101`。

`MediaQuery.displayFeaturesOf` 的 `bounds` 是窗口坐标，而 `FoldAwareBuilder` 同时向任意 `LayoutBuilder` 子树传入局部 `BoxConstraints`。示例直接使用 `fold.hingeBounds?.left` 作为局部分栏位置；当构建器在 `SafeArea`、带 AppBar 的 body 或嵌套面板内时，两个坐标系不保证一致。`HingeSplitLayout` 已限制“完整窗口宽度”才使用铰链，但 `FoldAwareBuilder` 本身没有此保护，API 容易被误用。

**建议改造：**

1. 不要将裸 `Rect` 作为局部布局位置直接暴露；将 `FoldInfo` 改为保存 `DisplayFeature` 列表及窗口坐标语义。
2. 新增只供全窗口使用的 `WindowFoldLayout`，在断言/运行时检查中要求覆盖完整可用窗口；仅该组件可产生“可用于分栏的铰链位置”。
3. 嵌套布局不做坐标猜测：返回 `null` 并使用普通比例分栏。浮层、弹窗和底部弹层使用 Flutter 的 `DisplayFeatureSubScreen`。
4. 文档中删除“把 `hingeBounds.left` 直接传给任意两栏布局”的示例，改为使用封装后的 pane bounds。

### P0：铰链拆分只支持垂直铰链，半开/笔记本形态缺少安全布局

**位置**：`lib/core/responsive/fold_aware.dart:188`、`lib/core/responsive/fold_aware.dart:204`、`lib/core/responsive/fold_aware.dart:211`。

`HingeSplitLayout` 仅检查 `hinge.width > 0` 并固定使用 `Row`。水平铰链的 `width` 通常等于窗口宽度，因此会回退到普通布局；如果该普通布局跨越物理铰链，交互控件仍可能落在遮挡区。`isHalfOpened` 只是布尔值，也不能告诉调用方铰链方向和两个可用面板的边界。

**建议改造：**

1. 定义 `FoldAxis { vertical, horizontal }`，从 `DisplayFeature.bounds` 的长边方向推导。
2. 用统一的 `HingePaneLayout` 取代仅左右语义的 `HingeSplitLayout`：垂直铰链使用 `Row`，水平铰链使用 `Column`；`first` / `second` 取代 `left` / `right`。
3. 计算并提供两个 pane 的 `Rect`、铰链安全间距与可用尺寸；宽或高无效时必须回退。
4. 新增水平铰链、平铺态、半开态、横竖屏切换的 widget test，确保内容不会跨越物理遮挡区域。

### P1：Token 体系过度依赖全局 `ScreenUtil`，且缩放入口过多

**位置**：`lib/core/responsive/responsive_tokens.dart:42`、`lib/core/responsive/responsive_tokens.dart:60`、`lib/core/responsive/responsive_tokens.dart:70`、`lib/core/responsive/responsive_tokens.dart:88`、`lib/core/responsive/responsive_tokens.dart:286`。

当前有 `compact`、`aw`、`tw`、`size`、`font`、`rsize`、`rfont`、`localSize`、`localFont` 与七个 `num` 扩展。它们混合全局窗口、局部约束、手机/平板设计稿及字体策略，使用者很难预测同一个值在不同父级中的行为，也使单元测试必须初始化 `ScreenUtil`。现有业务页面仍直接使用 `.w`、`.h`、`.r`，例如 `lib/features/auth/presentation/pages/login_page/login_page.dart:55` 和 `lib/features/auth/presentation/pages/profile_page.dart:26`，会绕过 Token 的大屏保护。

**建议改造：**

1. 默认 Token 改为固定逻辑像素（spacing、radius、component height、typography），页面布局差异用 `AdaptiveLayoutBuilder` 和显式 token scale 表达。
2. 将 API 收敛为 `ResponsiveValues.of(context)` / `ResponsiveSpacing.of(context)` 等 context-aware 对象；只保留一套局部约束来源。
3. 仅在确有两套设计稿且设计评审批准时保留平板缩放，删除或标记为内部 API 的 `tw`、`aw`、`rc` 等快捷扩展，避免新代码继续使用。
4. 全项目替换裸 `.w/.h/.r/.sp`：先处理登录页、个人页及共享按钮，再用 lint 或自定义 lint 限制业务页面新增调用。
5. 单独验证 100%、150%、200% 系统文字缩放下的截断、溢出和可点击区域；不要以屏幕宽度缩放替代无障碍文字缩放。

### P1：`StatefulAdaptiveBuilder` 始终持有并布局所有布局变体

**位置**：`lib/core/responsive/adaptive_builder.dart:168`、`lib/core/responsive/adaptive_builder.dart:196`。

`IndexedStack` 可以保留状态，但会同时保留所有布局树；不可见分支中的动画、流、焦点和资源仍可能工作，并且布局成本随变体增长。当前文档只提示内存开销，保护不足以避免页面误用。

**建议改造：**

1. 默认只使用 `AdaptiveLayoutBuilder`；表单值、滚动位置等需要保留的数据上提到 Controller、Riverpod 或 `PageStorageKey`。
2. 若保留该组件，给非激活分支包裹 `TickerMode(enabled: active)`，并明确其不适用于视频、地图、相机、持续订阅及同一 `GlobalKey` 的多套布局。
3. 增加断点切换测试：验证不可见分支不触发 tick、焦点不会残留、语义树只暴露当前分支。

### P2：断点模型和 API 边界需要更清晰

**位置**：`lib/core/responsive/breakpoints.dart:6`、`lib/core/responsive/breakpoints.dart:28`、`lib/core/responsive/constraints_scope.dart:36`。

三档模型适合当前手机/平板目标，但注释称“对齐 Material 3”容易让人误解为完整尺寸类实现；超宽平板/桌面全部落入 `expanded`，没有最大内容宽度、列数和导航密度的独立策略。另外，无界约束静默回退为 compact，可能掩盖把断点判断放入滚动/无界子树的错误。

**建议改造：**

1. 文档改为“采用 M3 compact/medium/expanded 三个阈值的子集”，并将 desktop/超宽屏列入后续扩展策略。
2. 引入可注入 `ResponsivePolicy`（断点、最小 pane 宽度、导航阈值），避免全局 `static const` 使品牌或产品线无法调整。
3. 提供 `tryFromConstraints` 返回 nullable；`fromConstraints` 在 debug 模式对无界宽度报出明确错误，要求调用方转用外层有界约束。
4. `ConstraintsScope.of` 使用明确异常信息而非依赖 `assert` 后的空值断言，便于 release 排障。

### P2：`ContentConstraint` 和折叠信息的数据模型可再收紧

**位置**：`lib/core/responsive/content_constraint.dart:34`、`lib/core/responsive/content_constraint.dart:39`、`lib/core/responsive/fold_aware.dart:43`。

`ContentConstraint` 当前将 `padding` 放在 `ConstrainedBox` 外，因此总宽度可能是 `maxWidth + padding`；这不一定错误，但 API 名称没有说明。`FoldInfo` 只保留首个 hinge/fold 和 `isHalfOpened`，后续若遇到多个显示特征或需要平铺/方向信息，调用方只能重新读取 `MediaQuery`。

**建议改造：**

1. 为 `ContentConstraint` 增加 `includePaddingInMaxWidth`（默认 `true`）或把 padding 明确命名为 `outerPadding`；构造函数断言 `maxWidth > 0`、`maxHeight == null || maxHeight > 0`。
2. `FoldInfo` 保留过滤后的不可变特征列表，并提供 `primaryHinge`、`axis`、`panes` 等派生属性；不要在调用方重新解析平台数据。

## 推荐实施顺序

| 阶段 | 工作项 | 验收标准 |
|---|---|---|
| 1 | 统一可用空间策略，修正 AppShell 导航阈值 | 678dp 窗口但 SafeArea/导航后内容不足时不展示拥挤的 Rail |
| 2 | 重构铰链坐标与轴向，替换 `HingeSplitLayout` | 垂直、水平铰链都能生成不跨铰链的 pane；嵌套场景安全回退 |
| 3 | 收敛 Token 与替换裸 ScreenUtil 调用 | 业务页无新增 `.w/.h/.r/.sp`；大屏间距不会按窗口倍数膨胀 |
| 4 | 收紧状态保持和内容约束 API | 不可见布局不运行 tick；最大宽度的 padding 语义明确且有测试 |
| 5 | 扩展测试矩阵和真机验收 | 覆盖文本缩放、键盘、分屏、横向外屏、两种铰链方向和旋转切换 |

## 建议测试矩阵

| 场景 | 必测点 |
|---|---|
| 普通手机 320/375/430dp | 单列、最小触控尺寸、长文本与 200% 字号 |
| 折叠外屏横向 | SafeArea 后内容不足时导航策略、表单不溢出 |
| 展开折叠屏 | compact→expanded 跨级切换、状态迁移、普通比例两栏 |
| 垂直物理铰链 | 两 pane 宽度、铰链及 margin 内无可交互内容 |
| 水平物理铰链/半开态 | 上下 pane、键盘与底部操作区不被遮挡 |
| 平板分屏/桌面窗口拖拽 | 连续跨过每个阈值、局部 panel 与全局窗口判定不混用 |
| 大屏列表/详情/表单 | 读取宽度上限、网格列数、Rail 与内容区的最小宽度 |

## 文档维护

现有文档对设备形态、平台限制和尺寸使用了较强的产品假设。建议将这些内容归入“已验证设备矩阵”，并在每个结论旁标注 Flutter 版本、OS/SDK 版本和验证方式。核心 API 文档只保留平台无关的 `MediaQuery.displayFeaturesOf` 行为、坐标系约束和 fallback 规则，避免产品叙述被误认为框架保证。

