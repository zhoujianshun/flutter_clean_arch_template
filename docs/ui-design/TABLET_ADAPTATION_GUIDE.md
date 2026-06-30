# Flutter 平板适配方案指南

本文档基于对项目现状的全面分析，给出平板适配的推荐方案和实施指南。

## 一、现状分析

### 当前适配架构

| 项目 | 现状 |
|------|------|
| ScreenUtil 设计稿 | `375 × 812`（iPhone X/11） |
| 屏幕方向 | 锁定竖屏（`portraitUp` / `portraitDown`） |
| 导航形式 | 仅 `NavigationBar`（底部导航栏） |
| 布局模式 | 单列 Column / ListView，全宽按钮 |
| 响应式工具 | `ResponsiveUtils` 已定义但未接入 |
| 弹性布局 | 极少使用 `Expanded` / `Flexible` |

### 平板上的核心问题

| 问题 | 原因 | 影响 |
|------|------|------|
| 字体过大 | ScreenUtil 默认按宽度缩放，平板宽度翻倍导致字体翻倍 | 文字溢出、比例失调 |
| 间距过度放大 | `.w` 值在平板上放大约 2 倍 | 内容稀疏、空间浪费 |
| 导航不合理 | 底部导航栏在大屏上浪费纵向空间 | 不符合 Material 3 平板规范 |
| 内容过度拉伸 | 单列布局铺满 768dp+ 宽度 | 阅读体验差、不专业 |
| 不支持横屏 | 方向锁定为竖屏 | 平板核心使用场景受限 |
| 无分栏布局 | 列表→详情为全屏跳转 | 未利用大屏空间优势 |

---

## 二、推荐方案：渐进式增强

### 设计原则

1. **基于可用空间而非设备类型**：使用 `LayoutBuilder` 的 `constraints.maxWidth` 做布局决策，不检测"手机还是平板"
2. **ScreenUtil 管微观，LayoutBuilder 管宏观**：ScreenUtil 负责间距/字体/圆角的缩放，LayoutBuilder 负责布局结构的切换
3. **渐进式迁移**：分层实施，每层独立可验证，不需要一次改完所有页面
4. **折叠屏友好**：窗口宽度变化时实时切换布局，无跳变

### 架构分层

```
┌─────────────────────────────────────────────────────────┐
│  第一层：基础设施修复                                      │
│  ScreenUtil fontSizeResolver + 解锁平板横屏               │
├─────────────────────────────────────────────────────────┤
│  第二层：导航适配                                          │
│  AppShellPage 自适应（NavigationBar ↔ NavigationRail）    │
├─────────────────────────────────────────────────────────┤
│  第三层：内容适配                                          │
│  页面布局变体（mobile / tablet）+ ConstrainedBox          │
├─────────────────────────────────────────────────────────┤
│  第四层：工具增强                                          │
│  ResponsiveUtils 激活 + 响应式组件库                       │
└─────────────────────────────────────────────────────────┘
```

完成第一、二层即可让平板**基本可用**，第三、四层让体验**更加完善**。

---

## 三、断点定义

遵循 Material 3 窗口尺寸类（Window Size Classes）：

| 尺寸类 | 宽度范围 | 典型设备 | 导航形式 |
|--------|---------|---------|---------|
| Compact | < 600dp | 手机 | NavigationBar（底部） |
| Medium | 600 - 1023dp | 平板竖屏、折叠屏展开 | NavigationRail（左侧） |
| Expanded | ≥ 1024dp | 平板横屏、桌面 | NavigationRail + 展开标签 |

```dart
// lib/shared/utils/responsive_utils.dart
class ResponsiveUtils {
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1024;
}
```

---

## 四、各层实施细节

### 第一层：基础设施修复

#### 4.1 ScreenUtil 字体缩放修复

添加 `fontSizeResolver`，使用宽高平衡缩放，防止平板上字体过大：

```dart
// lib/main.dart
ScreenUtilInit(
  designSize: const Size(375, 812),
  minTextAdapt: true,
  splitScreenMode: true,
  fontSizeResolver: (fontSize, instance) {
    final scaleW = instance.screenWidth / 375;
    final scaleH = instance.screenHeight / 812;
    final scale = (scaleW + scaleH) / 2;
    return fontSize * scale;
  },
  builder: (context, child) { ... },
)
```

**效果对比**（16sp 字体在不同设备上的实际大小）：

| 设备 | 屏幕宽度 | 修复前 | 修复后 |
|------|---------|--------|--------|
| iPhone 14 | 390dp | 16.6sp | 16.4sp |
| iPad Mini | 744dp | 31.7sp | 22.7sp |
| iPad Pro 11" | 834dp | 35.6sp | 24.1sp |
| iPad Pro 12.9" | 1024dp | 43.7sp | 27.9sp |

#### 4.2 解锁平板横屏

```dart
// lib/core/initializers/app_initializer.dart
import 'dart:ui';

// 根据屏幕短边判断是否为平板
final view = PlatformDispatcher.instance.views.first;
final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;

if (shortestSide >= 600) {
  // 平板：允许所有方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
} else {
  // 手机：保持竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}
```

---

### 第二层：导航适配

#### 4.3 AppShellPage 自适应导航

```dart
// lib/features/app/presentation/pages/app_shell.dart
@override
Widget build(BuildContext context) {
  return AutoTabsRouter(
    routes: const [ExampleListRoute(), ProfileRoute()],
    builder: (context, child) {
      final tabsRouter = AutoTabsRouter.of(context);
      return LayoutBuilder(
        builder: (context, constraints) {
          // 平板：左侧 NavigationRail + 右侧内容
          if (constraints.maxWidth >= 600) {
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: tabsRouter.activeIndex,
                    onDestinationSelected: tabsRouter.setActiveIndex,
                    labelType: constraints.maxWidth >= 1024
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.selected,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Profile'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: child),
                ],
              ),
            );
          }

          // 手机：底部 NavigationBar（保持原样）
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: tabsRouter.activeIndex,
              onDestinationSelected: tabsRouter.setActiveIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
```

---

### 第三层：内容适配

#### 4.4 页面布局策略

根据页面特征选择不同的适配策略：

| 页面类型 | 手机布局 | 平板布局 | 策略 |
|---------|---------|---------|------|
| 表单页（登录等） | 全宽 | 居中限宽（最大 480dp） | ConstrainedBox |
| 列表页 | 单列 | 双列网格 / Master-Detail | 布局变体 |
| 详情页 | 全屏 | 限宽居中（最大 680dp） | ConstrainedBox |
| 设置/Profile | 全宽 | 居中限宽（最大 600dp） | ConstrainedBox |

#### 4.5 ConstrainedBox 内容限宽

对于不需要重新设计平板布局的页面，简单限制最大宽度即可：

```dart
/// 通用内容约束组件
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    required this.child,
    super.key,
    this.maxWidth = 600,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
```

使用方式：

```dart
// 登录页 —— 在平板上居中显示，最大宽度 480dp
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ContentConstraint(
      maxWidth: 480,
      child: _buildLoginForm(),
    ),
  );
}
```

#### 4.6 页面布局变体（双设计稿场景）

对于设计师提供了手机和平板两套设计稿的关键页面，使用布局变体模式：

```
lib/features/example/presentation/pages/
├── example_list_page.dart              # 入口（LayoutBuilder 分发）
├── layouts/
│   ├── example_list_mobile.dart        # 手机布局（用 ScreenUtil .w/.sp）
│   └── example_list_tablet.dart        # 平板布局（用弹性布局比例）
```

入口页面：

```dart
// example_list_page.dart
@RoutePage()
class ExampleListPage extends StatelessWidget {
  const ExampleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return const ExampleListTablet();
        }
        return const ExampleListMobile();
      },
    );
  }
}
```

**ScreenUtil 与弹性布局的分工**：

```
手机布局文件 → 按手机设计稿写，正常使用 .w / .sp / .r
平板布局文件 → 按平板设计稿写，结构用 Expanded / FractionallySizedBox，
               共享子组件（按钮、卡片等）仍然使用 ScreenUtil
```

#### 4.7 Master-Detail 分栏（列表+详情）

平板上最有价值的适配模式——列表和详情并排显示：

```dart
// example_list_tablet.dart
class ExampleListTablet extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _ExampleListTabletState();
}

class _ExampleListTabletState extends ConsumerState<ExampleListTablet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧列表（占 35%-40%）
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.38,
          child: ExampleListPanel(
            selectedId: _selectedId,
            onItemSelected: (id) => setState(() => _selectedId = id),
          ),
        ),
        const VerticalDivider(width: 1),
        // 右侧详情（占剩余空间）
        Expanded(
          child: _selectedId != null
              ? ExampleDetailPanel(id: _selectedId!)
              : const Center(child: Text('Select an item')),
        ),
      ],
    );
  }
}
```

---

### 第四层：工具增强

#### 4.8 增强 ResponsiveUtils

激活已有的 `ResponsiveUtils` 并补充实用方法：

```dart
// lib/shared/utils/responsive_utils.dart

class ResponsiveUtils {
  // 断点常量（对齐 Material 3 Window Size Classes）
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1024;

  /// 基于 LayoutBuilder 约束判断（推荐）
  static bool isCompact(BoxConstraints constraints) =>
      constraints.maxWidth < compactBreakpoint;

  static bool isMedium(BoxConstraints constraints) =>
      constraints.maxWidth >= compactBreakpoint &&
      constraints.maxWidth < expandedBreakpoint;

  static bool isExpanded(BoxConstraints constraints) =>
      constraints.maxWidth >= expandedBreakpoint;

  /// 基于约束返回响应式值
  static T valueOf<T>(
    BoxConstraints constraints, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    if (isExpanded(constraints) && expanded != null) return expanded;
    if (isMedium(constraints) && medium != null) return medium;
    return compact;
  }

  /// 自适应网格列数
  static int gridColumns(BoxConstraints constraints) =>
      valueOf(constraints, compact: 2, medium: 3, expanded: 4);
}
```

#### 4.9 AdaptiveBuilder 组件

```dart
/// 自适应布局构建器
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({
    required this.compact,
    super.key,
    this.medium,
    this.expanded,
  });

  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024 && expanded != null) {
          return expanded!;
        }
        if (constraints.maxWidth >= 600 && medium != null) {
          return medium!;
        }
        return compact;
      },
    );
  }
}
```

---

## 五、双设计稿的尺寸处理策略

当设计师同时提供手机稿（375×812）和平板稿（768×1024）时：

### 分层处理原则

| 层级 | 内容 | 处理方式 |
|------|------|---------|
| 原子层 | 间距、字体、圆角、图标 | ScreenUtil（手机 designSize），平板自动缩放 |
| 结构层 | 分栏比例、面板宽度、导航 | 弹性布局（Expanded / 百分比），按平板稿比例 |
| 组件层 | 按钮、卡片、输入框 | 共享组件用 ScreenUtil，外层用 ConstrainedBox 限宽 |

### 平板设计稿中的比例信息用法

```dart
// 平板设计稿标注：左栏 280dp / 总宽 768dp ≈ 36.5%
// 代码中使用比例，不使用绝对值
Row(
  children: [
    SizedBox(
      width: constraints.maxWidth * 0.365,  // 对应平板稿比例
      child: listPanel,
    ),
    Expanded(child: detailPanel),
  ],
)
```

### 个别差异值的处理

如果平板设计稿中某个值与手机稿差异显著（不是简单的缩放关系），使用 `responsiveValue`：

```dart
// 手机稿：边距 16dp，平板稿：边距 32dp
padding: EdgeInsets.symmetric(
  horizontal: ResponsiveUtils.valueOf(
    constraints,
    compact: 16.w,
    medium: 32,   // 平板不经过 ScreenUtil，直接用平板稿值
  ),
)
```

---

## 六、适配检查清单

### 新增页面时

- [ ] 页面是否需要平板布局变体？（列表类、Dashboard 类需要）
- [ ] 表单/详情页是否添加了 `ContentConstraint` 限宽？
- [ ] 是否使用了 `LayoutBuilder` 而非 `MediaQuery` 做布局判断？
- [ ] 布局是否在 600dp 和 1024dp 断点处表现正常？
- [ ] 横屏模式下是否有溢出？

### 新增共享组件时

- [ ] 组件是否支持在 ConstrainedBox 内正常显示？
- [ ] 组件宽度是否使用了 `double.infinity` 或 `Expanded`，而非硬编码？
- [ ] 是否避免了使用 `MediaQuery.sizeOf(context).width` 做组件内部尺寸？

### 测试设备

| 设备 | 分辨率（逻辑像素） | 用途 |
|------|-----------------|------|
| iPhone SE | 375 × 667 | 小屏手机基准 |
| iPhone 14 Pro | 393 × 852 | 标准手机 |
| iPad Mini | 744 × 1133 | 小平板（竖屏） |
| iPad Air | 820 × 1180 | 标准平板（竖屏） |
| iPad Pro 11" | 834 × 1194 | 大平板（竖屏/横屏） |
| iPad Pro 12.9" | 1024 × 1366 | 超大平板（横屏） |

---

## 七、实施路线图

```
Phase 1（基础可用）—— 预计 1-2 天
├── ScreenUtil fontSizeResolver 配置
├── 平板横屏解锁
└── AppShellPage 自适应导航

Phase 2（内容适配）—— 预计 2-3 天
├── ContentConstraint 组件
├── 表单页/详情页限宽
├── 列表页双列网格
└── ResponsiveUtils 增强

Phase 3（精细化）—— 预计 3-5 天
├── Master-Detail 分栏示例
├── 关键页面平板布局变体
├── 适配检查 & 测试
└── 文档同步更新
```

---

## 八、常见问题

### Q: 为什么不用两个 designSize？

ScreenUtil 在 Widget 树根部初始化，全局只有一个 `designSize`。运行时切换会导致所有 `.w` 值的含义瞬间改变，在折叠屏展开/折叠时产生明显的 UI 跳变。保持单一 designSize + `fontSizeResolver` 补偿是更稳定的方案。

### Q: 为什么不拆成两个 App（Monorepo）？

单 App 方案更适合"同一应用的自适应"场景。折叠屏设备在展开/折叠时窗口尺寸连续变化，单 App + LayoutBuilder 可以实时切换布局。双 App 方案无法处理这种连续变化，且增加了工程复杂度和应用商店管理成本。

### Q: 平板上 `.w` 值放大太多怎么办？

对于内容页面，使用 `ContentConstraint` 限制最大宽度。对于个别需要精细控制的值，使用 `ResponsiveUtils.valueOf` 为平板指定独立的值。

### Q: 是否需要引入 responsive_framework 或 adaptive_scaffold 等第三方包？

当前方案使用 Flutter 原生的 `LayoutBuilder`、`NavigationRail`、`ConstrainedBox` 即可满足需求，无需额外依赖。这降低了维护成本，也让模板的使用者更容易理解底层原理。
