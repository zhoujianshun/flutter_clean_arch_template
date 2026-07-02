# 响应式适配组件 API 参考

本文档介绍项目中用于手机/平板适配的核心组件和工具类的用法。

## 目录

- [断点定义](#断点定义)
- [ResponsiveUtils 工具类](#responsiveutils-工具类)
- [AdaptiveBuilder 自适应构建器](#adaptivebuilder-自适应构建器)
- [AdaptiveLayoutBuilder 自适应布局构建器](#adaptivelayoutbuilder-自适应布局构建器)
- [ContentConstraint 内容约束](#contentconstraint-内容约束)
- [ResponsiveBuilder 响应式构建器](#responsivebuilder-响应式构建器)
- [AppShellPage 自适应导航](#appshellpage-自适应导航)
- [示例页面](#示例页面)
- [最佳实践](#最佳实践)

---

## 断点定义

对齐 Material 3 窗口尺寸类（Window Size Classes）：

| 尺寸类 | 宽度范围 | 典型设备 | 常量 |
|--------|---------|---------|------|
| Compact（紧凑） | < 600dp | 手机 | `ResponsiveUtils.compactBreakpoint` |
| Medium（中等） | 600-1023dp | 平板竖屏、折叠屏 | — |
| Expanded（扩展） | ≥ 1024dp | 平板横屏、桌面 | `ResponsiveUtils.expandedBreakpoint` |

---

## ResponsiveUtils 工具类

**路径**: `lib/shared/responsive/responsive_utils.dart`

### 基于约束的方法（推荐）

配合 `LayoutBuilder` 使用，响应父组件的实际约束：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // 判断当前尺寸类
    if (ResponsiveUtils.isCompact(constraints)) { ... }
    if (ResponsiveUtils.isMedium(constraints)) { ... }
    if (ResponsiveUtils.isExpanded(constraints)) { ... }

    // 根据尺寸类返回不同的值
    final columns = ResponsiveUtils.valueOf(
      constraints,
      compact: 1,    // 手机
      medium: 2,     // 平板竖屏
      expanded: 3,   // 平板横屏/桌面
    );

    // 快捷方法
    final listColumns = ResponsiveUtils.gridColumns(constraints);    // 1/2/3
    final itemColumns = ResponsiveUtils.itemGridColumns(constraints); // 2/3/4
  },
)
```

### 基于 Context 的方法（兼容旧代码）

在无法使用 `LayoutBuilder` 的场景（如主题配置）：

```dart
// 设备类型判断
ResponsiveUtils.isMobile(context);   // < 600dp
ResponsiveUtils.isTablet(context);   // 600-1023dp
ResponsiveUtils.isDesktop(context);  // >= 1024dp

// 响应式值
final padding = ResponsiveUtils.responsiveValue(
  context,
  mobile: 16.w,
  tablet: 32,
  desktop: 48,
);

// 辅助方法
ResponsiveUtils.getHorizontalPadding(context);
ResponsiveUtils.getMaxContentWidth(context);
ResponsiveUtils.getCardSpacing(context);
```

### 两套方法的选择

| 场景 | 推荐方法 | 原因 |
|------|---------|------|
| 页面布局切换 | `isCompact(constraints)` | 响应父约束，折叠屏友好 |
| 网格列数 | `gridColumns(constraints)` | 同上 |
| 主题/全局配置 | `responsiveValue(context)` | 无 LayoutBuilder 可用 |
| 方向/安全区域 | `isLandscape(context)` | 这些只能通过 MediaQuery 获取 |

---

## AdaptiveBuilder 自适应构建器

**路径**: `lib/shared/responsive/adaptive_builder.dart`

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
  medium: TabletLayout(),       // 600-1023dp
  expanded: DesktopLayout(),    // >= 1024dp
)
```

### 回退规则

- expanded 宽度但 `expanded` 为 null → 使用 `medium`
- medium 宽度但 `medium` 为 null → 使用 `expanded`（如有）或 `compact`

### 三者对比

| | AdaptiveBuilder | AdaptiveLayoutBuilder | LayoutBuilder |
|-|:---:|:---:|:---:|
| 用途 | 纯布局切换 | 布局切换 + 约束计算 | 连续值计算 |
| 参数 | Widget | Widget Function(BoxConstraints) | BoxConstraints |
| 适合 | 子组件不需要 constraints | 子组件需要 constraints 做分栏/比例 | 列数/间距等非分支场景 |

---

## AdaptiveLayoutBuilder 自适应布局构建器

**路径**: `lib/shared/responsive/adaptive_builder.dart`

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

### 何时选择 AdaptiveLayoutBuilder 而非 AdaptiveBuilder

- 子组件需要 `constraints` 来决定分栏宽度、flex 比例等 → `AdaptiveLayoutBuilder`
- 子组件不需要 `constraints`，纯切换 → `AdaptiveBuilder`（更简洁）
- 不是离散分支，而是用 constraints 做连续计算（如列数、间距）→ 直接用 `LayoutBuilder`

---

## ContentConstraint 内容约束

**路径**: `lib/shared/responsive/content_constraint.dart`

在大屏上限制内容最大宽度并居中。手机上无视觉影响。

```dart
// 登录页 —— 使用语义化常量
ContentConstraint(
  maxWidth: ResponsiveUtils.maxWidthForm,     // 480dp
  child: LoginForm(),
)

// 详情页 —— 限制阅读宽度
ContentConstraint(
  maxWidth: ResponsiveUtils.maxWidthDetail,   // 680dp
  child: ArticleContent(),
)

// 设置页 —— 带外边距
ContentConstraint(
  maxWidth: ResponsiveUtils.maxWidthList,     // 600dp
  padding: EdgeInsets.all(16),
  child: SettingsList(),
)
```

### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `child` | Widget | 必填 | 子组件 |
| `maxWidth` | double | 600 | 最大宽度限制（dp） |
| `alignment` | Alignment | topCenter | 对齐方式 |
| `padding` | EdgeInsets? | null | 可选外边距 |

### 推荐 maxWidth 值

| 页面类型 | 常量 | 值 | 说明 |
|---------|------|-----|------|
| 窄表单（登录右侧） | `ResponsiveUtils.maxWidthFormNarrow` | 420dp | 分栏登录的表单侧 |
| 标准表单（登录/注册） | `ResponsiveUtils.maxWidthForm` | 480dp | 表单不宜过宽 |
| 列表/设置页 | `ResponsiveUtils.maxWidthList` | 600dp | 标准内容宽度 |
| 详情/文章页 | `ResponsiveUtils.maxWidthDetail` | 680dp | 适合长文阅读 |

---

## ResponsiveBuilder 响应式构建器

**路径**: `lib/shared/responsive/responsive_utils.dart`

基于 `MediaQuery` 屏幕宽度切换子组件（vs AdaptiveBuilder 基于 LayoutBuilder）：

```dart
ResponsiveBuilder(
  mobile: MobileView(),
  tablet: TabletView(),
  desktop: DesktopView(),   // 可选
)
```

> 大多数场景推荐使用 `AdaptiveBuilder`，因为它基于父约束而非全屏宽度，折叠屏/分屏更友好。

---

## AppShellPage 自适应导航

**路径**: `lib/features/app/presentation/pages/app_shell.dart`

自动切换导航形式：

| 屏幕宽度 | 导航形式 | 标签显示 |
|---------|---------|---------|
| < 600dp | NavigationBar（底部） | 图标 + 标签 |
| 600-1023dp | NavigationRail（左侧） | 图标 + 选中标签 |
| ≥ 1024dp | NavigationRail（左侧） | 图标 + 所有标签 |

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

项目包含 8 个响应式适配示例页面，可从 **Profile → Responsive Demo** 进入：

### 1. Dashboard 仪表盘

**文件**: `lib/features/_responsive_demo/presentation/pages/responsive_dashboard_page.dart`

| 手机 | 平板竖屏 | 平板横屏/桌面 |
|------|---------|------------|
| 单列卡片列表 | 2 列统计网格 + 动态列表 | 左侧主面板（65%）+ 右侧动态边栏（35%） |

**学习要点**：
- 使用 `AdaptiveLayoutBuilder` 的三级回调（compact/medium/expanded）切换三种完全不同的布局
- `GridView.count` 配合 `shrinkWrap: true` 嵌套在 `ListView` 中
- `Row` + `Expanded(flex:)` 实现按比例分栏

### 2. Master-Detail 分栏

**文件**: `lib/features/_responsive_demo/presentation/pages/master_detail_page.dart`

| 手机 | 平板 |
|------|------|
| 列表页 → push 全屏详情页 | 左侧列表面板 + 右侧详情面板 |

**学习要点**：
- 使用 `AdaptiveLayoutBuilder` 切换手机/平板布局
- 手机用 `context.router.push(MasterDetailDetailRoute(...))` 通过 AutoRoute 导航到独立详情页
- 详情页提取为独立 `@RoutePage`（`master_detail_detail_page.dart`），支持路由守卫和 deep link
- 平板用 `setState` 更新右侧面板（不走路由）
- 列表项选中态高亮（`isSelected` → `primaryContainer` 背景色）
- 详情面板使用 `ContentConstraint` 限制阅读宽度
- `masterRatio` 根据 expanded/medium 动态调整

### 3. 响应式表单

**文件**: `lib/features/_responsive_demo/presentation/pages/responsive_form_page.dart`

| 手机 | 平板 |
|------|------|
| 全宽单列字段 | 居中卡片 + 关联字段双列排列 |

**学习要点**：
- 使用 `AdaptiveBuilder`（纯 Widget 版）切换布局——子组件不需要 constraints
- 手机用 `.w` / `.h` 扩展做间距
- 平板用固定 dp + `ContentConstraint` + `Card` 容器
- 关联字段（姓/名、省/市）用 `Row` + `Expanded` 双列排列
- 按钮从全宽 `FilledButton` 变为右对齐 `OutlinedButton` + `FilledButton`

### 4. 自适应网格画廊

**文件**: `lib/features/_responsive_demo/presentation/pages/responsive_gallery_page.dart`

| 手机 | 平板竖屏 | 平板横屏/桌面 |
|------|---------|------------|
| 2 列 | 3 列 | 4 列 |

**学习要点**：
- `ResponsiveUtils.itemGridColumns(constraints)` 一行获取列数
- `ResponsiveUtils.valueOf` 获取响应式间距
- `GridView.builder` + `SliverGridDelegateWithFixedCrossAxisCount`

### 5. 设置页分栏

**文件**: `lib/features/_responsive_demo/presentation/pages/responsive_settings_page.dart`

| 手机 | 平板 |
|------|------|
| 分组卡片列表（通用/外观/通知/隐私/关于） | 左侧分类导航菜单 + 右侧设置项面板 |

**学习要点**：
- 与 Master-Detail 类似的分栏，但左侧是固定的分类菜单而非动态数据列表
- `ListTile.selected` + `selectedTileColor` 实现选中高亮
- `Switch`、`TextButton`、`Icon` 等不同类型的设置项尾部组件
- 右侧面板使用 `ContentConstraint` 限制宽度 + `Card` 分组
- `switch` 表达式根据 `_ItemType` 枚举动态渲染 `trailing` 组件

### 6. 图文详情页

**文件**: `lib/features/_responsive_demo/presentation/pages/responsive_article_page.dart`

| 手机 | 平板 |
|------|------|
| 图片在上 + 文字在下，纵向滚动 | 左侧图片区（固定宽度）+ 右侧文字内容（弹性宽度） |

**学习要点**：
- 手机使用 `Column` 纵向排列，平板使用 `Row` 横向并排
- 左侧图片区域包含主图 + 缩略图网格（`GridView.count`）
- 右侧文字区域使用 `ContentConstraint` 限制阅读宽度
- `Wrap` 实现标签流式布局
- `Row` + `Expanded(flex:)` 实现底部按钮比例布局（收藏1 : 购买2）

### 7. 登录页

**文件**: `lib/features/_responsive_demo/presentation/pages/responsive_login_page.dart`

| 手机 | 平板 |
|------|------|
| 全屏表单，Logo 在顶部 | 左侧品牌展示区（渐变背景 + 标语）+ 右侧登录表单 |

**学习要点**：
- SaaS/企业应用中非常经典的登录页布局
- 左侧品牌区使用 `LinearGradient` 渐变 + `Wrap` 特性标签
- `flex` 比例在 expanded 下调大（55:45），medium 下均分（45:55）
- 右侧表单使用 `ConstrainedBox(maxWidth: 420)` + `Center` 居中
- 手机使用 `.w` / `.h` 扩展做间距，平板使用固定 dp
- 第三方登录按钮行、分隔线等完整登录页元素

### 8. 聊天对话

**文件**: `lib/features/_responsive_demo/presentation/pages/responsive_chat_page.dart`

| 手机 | 平板 |
|------|------|
| 联系人列表 → push 全屏对话页 | 左侧联系人列表 + 右侧对话窗口 |

**学习要点**：
- 与 Master-Detail 类似但包含聊天特有的 UI 要素
- 消息气泡左右对齐（`MainAxisAlignment.start` / `.end`）
- 气泡圆角方向区分（发送方右下角方，接收方左下角方）
- 在线状态圆点（`Stack` + `Positioned` 叠加在头像上）
- 未读消息数角标
- 底部输入框固定在键盘上方（`SafeArea(top: false)`）
- 手机用 `Navigator.push()` 进入对话（有意保留原生导航，因为对话页是内部临时视图），平板用 `setState` 切换右侧面板
- 对比 `MasterDetailPage` 的 AutoRoute 方案，了解两种导航选择的取舍

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
  builder: (context, c) => GridView(crossAxisCount: ResponsiveUtils.gridColumns(c)),
)

// ❌ 避免：使用全屏宽度判断局部布局
if (MediaQuery.sizeOf(context).width < 600) { ... }
```

### 2. 不要检测设备类型

```dart
// ❌ 不要这样做
if (Platform.isAndroid && isTabletDevice()) { ... }

// ✅ 基于可用空间
if (constraints.maxWidth >= 600) { ... }
```

### 3. ScreenUtil 只管微观尺寸

```dart
// ✅ ScreenUtil 用于间距/字体/圆角
padding: EdgeInsets.all(16.w),
fontSize: 14.sp,
borderRadius: BorderRadius.circular(8.r),

// ✅ 布局结构用 Expanded/FractionallySizedBox
Row(children: [Expanded(flex: 35, child: list), Expanded(flex: 65, child: detail)])

// ❌ 不要用 ScreenUtil 做布局决策
if (1.sw > 600) { ... }  // 不要这样
```

### 4. 新增页面的适配策略

| 页面类型 | 最小适配（推荐所有页面） | 进阶适配（重要页面） |
|---------|:---:|:---:|
| 表单页 | `ContentConstraint(maxWidth: ResponsiveUtils.maxWidthForm)` | 双列字段布局 |
| 列表页 | `ContentConstraint(maxWidth: ResponsiveUtils.maxWidthList)` | 多列网格 / Master-Detail |
| 详情页 | `ContentConstraint(maxWidth: ResponsiveUtils.maxWidthDetail)` | — |
| Dashboard | — | 多面板 + 边栏 |

### 5. 页面布局变体的文件组织

当一个页面在手机和平板上有完全不同的 UI 设计时：

```
lib/features/xxx/presentation/pages/
├── xxx_page.dart                  # 入口（LayoutBuilder 分发）
├── layouts/
│   ├── xxx_mobile.dart            # 手机布局
│   └── xxx_tablet.dart            # 平板布局
```

入口文件：

```dart
@RoutePage()
class XxxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      compact: const XxxMobile(),
      medium: const XxxTablet(),
    );
  }
}
```
