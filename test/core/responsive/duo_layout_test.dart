import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/core/responsive/constraints_scope.dart';
import 'package:flutter_clean_arch_template/core/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/core/responsive/fold_aware.dart';
import 'package:flutter_clean_arch_template/core/responsive/layout_semantics.dart';
import 'package:flutter_clean_arch_template/core/responsive/responsive_context.dart';
import 'package:flutter_clean_arch_template/core/responsive/responsive_tokens.dart';
import 'package:flutter_clean_arch_template/shared/widgets/navigation/my_bottom_navigation_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// iPhone Duo（2026）尺寸速查（逻辑点 dp，@3x）
///
/// 数据来源：safearea.info（Xcode 27.1 模拟器实测）+ Apple HIG
///
/// ┌────────────────┬────────────┬─────────────────┬───────────────┬──────────────┐
/// │ 形态           │ 完整窗口    │ SafeArea inset  │ SafeArea 可用  │ 断点判定结果  │
/// │                │ (w × h)    │ (L, R, T, B)    │ (w × h)       │ (用完整窗口宽) │
/// ├────────────────┼────────────┼─────────────────┼───────────────┼──────────────┤
/// │ 外屏竖持        │ 466 × 678  │ 0, 84, 0, 34   │ 382 × 644     │ compact      │
/// │ 外屏横持        │ 678 × 466  │ 0, 84, 0, 34   │ 594 × 432     │ medium ⚠️    │
/// │ 内屏竖持        │ 669 × 951  │ 0, 0, 82, 34   │ 669 × 835     │ medium       │
/// │ 内屏横持        │ 951 × 669  │ 0, 84, 0, 34   │ 867 × 635     │ expanded     │
/// └────────────────┴────────────┴─────────────────┴───────────────┴──────────────┘
///
/// ⚠️ 外屏横持：完整窗口宽 678 ≥ 600 → medium，但 SafeArea 可用宽仅 594 < 600。
///    Apple size class 也为 compact × compact。当前断点判定基于完整窗口宽度
///    （与 LayoutBuilder / MediaQuery.sizeOf 一致），这是 Flutter 生态通用做法，
///    但会导致外屏横持渲染 NavigationRail（medium 布局）而非底部导航（compact）。
///    待 Flutter 官方明确「断点是否应扣 SafeArea inset」后再行调整。
///
/// 注意：断点判定使用**完整窗口宽度**（LayoutBuilder.maxWidth / MediaQuery.sizeOf），
/// 而非 SafeArea 后的可用宽度。两者仅在内屏竖持（系统保持标准水平 bar、
/// 无 side inset）时相等；外屏竖持/横持、内屏横持均有右侧 84pt 垂直控件条带，
/// 完整窗口宽 ≠ SafeArea 可用宽。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===================================================================
  // 断点判定（含边界值）
  // ===================================================================
  group('断点判定', () {
    test('iPhone Duo 折叠外屏 466pt → compact', () {
      expect(ResponsiveBreakpoints.fromWidth(466), WindowSizeClass.compact);
    });

    test('外屏横持 完整窗口宽 678pt → medium（已知限制：SafeArea 594 < 600）', () {
      // 完整窗口宽 678 ≥ 600 → medium，但 SafeArea 可用宽仅 594 < 600。
      // 当前断点基于完整窗口宽度，与 LayoutBuilder/MediaQuery.sizeOf 一致。
      // 待 Flutter 官方明确后可改为 SafeArea 宽度。
      expect(ResponsiveBreakpoints.fromWidth(678), WindowSizeClass.medium);
    });

    test('内屏竖持 完整窗口宽 669pt → medium', () {
      expect(ResponsiveBreakpoints.fromWidth(669), WindowSizeClass.medium);
    });

    test('内屏横持 完整窗口宽 951pt → expanded', () {
      expect(ResponsiveBreakpoints.fromWidth(951), WindowSizeClass.expanded);
    });

    test('边界 599pt → compact', () {
      expect(ResponsiveBreakpoints.fromWidth(599), WindowSizeClass.compact);
    });

    test('边界 600pt → medium', () {
      expect(ResponsiveBreakpoints.fromWidth(600), WindowSizeClass.medium);
    });

    test('边界 839pt → medium', () {
      expect(ResponsiveBreakpoints.fromWidth(839), WindowSizeClass.medium);
    });

    test('边界 840pt → expanded', () {
      expect(ResponsiveBreakpoints.fromWidth(840), WindowSizeClass.expanded);
    });

    test('无限宽度约束回退为 compact', () {
      const unbounded = BoxConstraints();
      expect(
        ResponsiveBreakpoints.fromConstraints(unbounded),
        WindowSizeClass.compact,
      );
    });
  });

  // ===================================================================
  // 渐进回退链（medium 缺失时不跳到 expanded）
  // ===================================================================
  group('渐进回退（valueOf）', () {
    test('medium 宽度、仅传 compact → 回退 compact', () {
      final result = ResponsiveBreakpoints.valueOf(
        const BoxConstraints(maxWidth: 700),
        compactValue: 'compact',
      );
      expect(result, 'compact');
    });

    test('medium 宽度、传 compact+expanded → 回退 compact（不跳 expanded）', () {
      final result = ResponsiveBreakpoints.valueOf(
        const BoxConstraints(maxWidth: 700),
        compactValue: 'compact',
        expandedValue: 'expanded',
      );
      expect(result, 'compact');
    });

    test('expanded 宽度、仅传 compact+medium → 回退 medium', () {
      final result = ResponsiveBreakpoints.valueOf(
        const BoxConstraints(maxWidth: 900),
        compactValue: 'compact',
        mediumValue: 'medium',
      );
      expect(result, 'medium');
    });

    test('expanded 宽度、仅传 compact → 回退 compact', () {
      final result = ResponsiveBreakpoints.valueOf(
        const BoxConstraints(maxWidth: 900),
        compactValue: 'compact',
      );
      expect(result, 'compact');
    });
  });

  // ===================================================================
  // AdaptiveBuilder 渐进回退
  // ===================================================================
  group('AdaptiveBuilder 渐进回退', () {
    Widget harness({Widget? medium, Widget? expanded}) {
      return MaterialApp(
        home: Scaffold(
          body: AdaptiveBuilder(
            compact: const Text('compact'),
            medium: medium,
            expanded: expanded,
          ),
        ),
      );
    }

    testWidgets('890pt + 仅 compact+medium → 回退 medium', (tester) async {
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(medium: const Text('medium')));
      expect(find.text('medium'), findsOneWidget);
      expect(find.text('compact'), findsNothing);
    });

    testWidgets('700pt + 仅 compact+expanded → 回退 compact（不跳 expanded）', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(expanded: const Text('expanded')));
      expect(find.text('compact'), findsOneWidget);
      expect(find.text('expanded'), findsNothing);
    });

    testWidgets('466pt → compact', (tester) async {
      tester.view.physicalSize = const Size(466, 678);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(medium: const Text('medium')));
      expect(find.text('compact'), findsOneWidget);
    });
  });

  // ===================================================================
  // Token clamp
  // ===================================================================
  group('Token clamp（防止大屏过度放大）', () {
    testWidgets('rs 在 compact 窗口按设计稿缩放并 clamp', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => const Scaffold(body: SizedBox()),
          ),
        ),
      );

      // 430/375 = 1.147, clamp 1.15 → 16 * 1.147 ≈ 18.35
      expect(16.rs, closeTo(16 * (430 / 375), 0.01));
    });
  });

  // ===================================================================
  // FoldInfo 姿态解析
  // ===================================================================
  group('FoldInfo 解析', () {
    testWidgets('普通设备（无 displayFeatures）→ none', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final fold = FoldInfo.fromContext(context);
              expect(fold.obstruction, isNull);
              expect(fold.foldCrease, isNull);
              expect(fold.isHalfOpened, isFalse);
              expect(fold.isFoldable, isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('hinge → obstruction 有值、foldCrease 为 null', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Builder(
              builder: (context) {
                final fold = FoldInfo.fromContext(context);
                expect(fold.isFoldable, isTrue);
                expect(fold.obstruction, const Rect.fromLTRB(440, 0, 450, 890));
                expect(fold.foldCrease, isNull);
                expect(fold.isHalfOpened, isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('fold → foldCrease 有值、obstruction 为 null', (tester) async {
      const foldFeature = DisplayFeature(
        bounds: Rect.fromLTRB(312, 0, 314, 890),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(626, 890),
              displayFeatures: [foldFeature],
            ),
            child: Builder(
              builder: (context) {
                final fold = FoldInfo.fromContext(context);
                expect(fold.isFoldable, isTrue);
                expect(fold.obstruction, isNull);
                expect(fold.foldCrease, const Rect.fromLTRB(312, 0, 314, 890));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('半开姿态 → isHalfOpened = true', (tester) async {
      const halfOpenHinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [halfOpenHinge],
            ),
            child: Builder(
              builder: (context) {
                final fold = FoldInfo.fromContext(context);
                expect(fold.isHalfOpened, isTrue);
                expect(fold.obstruction, isNotNull);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('cutout 不影响折叠信息', (tester) async {
      const cutout = DisplayFeature(
        bounds: Rect.fromLTRB(100, 0, 130, 30),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              displayFeatures: [cutout],
            ),
            child: Builder(
              builder: (context) {
                final fold = FoldInfo.fromContext(context);
                expect(fold.isFoldable, isFalse);
                expect(fold.obstruction, isNull);
                expect(fold.foldCrease, isNull);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

  });

  // HingeSplitLayout 测试已迁移到 HingePaneLayout 测试组

  // ===================================================================
  // FoldAxis 推导
  // ===================================================================
  group('FoldAxis 推导', () {
    test('垂直铰链（height > width）→ vertical', () {
      const fold = FoldInfo(
        obstruction: Rect.fromLTRB(440, 0, 450, 890),
      );
      expect(fold.axis, FoldAxis.vertical);
    });

    test('水平铰链（width > height）→ horizontal', () {
      const fold = FoldInfo(
        obstruction: Rect.fromLTRB(0, 440, 890, 450),
      );
      expect(fold.axis, FoldAxis.horizontal);
    });

    test('无铰链/折痕 → null', () {
      expect(FoldInfo.none.axis, isNull);
    });

    test('折痕也可推导轴向', () {
      const fold = FoldInfo(
        foldCrease: Rect.fromLTRB(312, 0, 314, 890),
      );
      expect(fold.axis, FoldAxis.vertical);
    });

    test('features 列表保留过滤后的 hinge/fold', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );
      const cutout = DisplayFeature(
        bounds: Rect.fromLTRB(100, 0, 130, 30),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      );

      final fold = FoldInfo(
        obstruction: hinge.bounds,
        features: [hinge],
      );
      // cutout 不在 features 中
      expect(fold.features, hasLength(1));
      expect(fold.features.first.type, DisplayFeatureType.hinge);
    });
  });

  // ===================================================================
  // HingePaneLayout
  // ===================================================================
  group('HingePaneLayout', () {
    testWidgets('无铰链时使用 fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HingePaneLayout(
              first: Text('first'),
              second: Text('second'),
              fallback: Text('fallback'),
            ),
          ),
        ),
      );

      expect(find.text('fallback'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });

    testWidgets('垂直铰链时使用 Row 左右分栏', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: HingePaneLayout(
                first: Text('first'),
                second: Text('second'),
                fallback: Text('fallback'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('水平铰链时使用 Column 上下分栏', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(0, 440, 890, 450),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: SizedBox(
                width: 890,
                height: 890,
                child: HingePaneLayout(
                  first: const Text('top'),
                  second: const Text('bottom'),
                  fallback: const Text('fallback'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('top'), findsOneWidget);
      expect(find.text('bottom'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('嵌套子面板时回退 fallback', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  child: HingePaneLayout(
                    first: Text('first'),
                    second: Text('second'),
                    fallback: Text('fallback'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('fallback'), findsOneWidget);
    });
  });

  // ===================================================================
  // FoldAwareBuilder 嵌套保护
  // ===================================================================
  group('FoldAwareBuilder 嵌套保护', () {
    testWidgets('非全窗口时 fold 回退为 FoldInfo.none', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FoldInfo? capturedFold;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: Row(
                children: [
                  const SizedBox(width: 200),
                  Expanded(
                    child: FoldAwareBuilder(
                      compact: (_, fold) {
                        capturedFold = fold;
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(capturedFold, isNotNull);
      expect(capturedFold!.isFoldable, isFalse,
          reason: '嵌套场景应收到 FoldInfo.none');
    });

    testWidgets('全窗口时正常传递 FoldInfo', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FoldInfo? capturedFold;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: FoldAwareBuilder(
                compact: (_, fold) {
                  capturedFold = fold;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedFold, isNotNull);
      expect(capturedFold!.isFoldable, isTrue,
          reason: '全窗口场景应正常传递 FoldInfo');
    });
  });

  // ===================================================================
  // ContentConstraint
  // ===================================================================
  group('ContentConstraint', () {
    testWidgets('窄于 maxWidth 时不约束', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentConstraint(
              key: Key('content-constraint-narrow'),
              child: SizedBox(width: double.infinity, height: 100),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byKey(const Key('content-constraint-narrow')),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.size.width, lessThanOrEqualTo(400));
    });

    testWidgets('maxHeight 正确约束', (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentConstraint(
              key: Key('content-constraint'),
              maxHeight: 300,
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      // 测量 ContentConstraint 内部 ConstrainedBox 的子节点尺寸，
      // 避免误抓 Scaffold 内部的 ConstrainedBox
      final constrained = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byKey(const Key('content-constraint')),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrained.size.height, lessThanOrEqualTo(300));
      expect(constrained.size.width, lessThanOrEqualTo(600));
    });
  });

  // ===================================================================
  // ConstraintsScope 注入
  // ===================================================================
  group('ConstraintsScope 注入', () {
    testWidgets('AdaptiveBuilder 子树中可读取 ConstraintsScope', (tester) async {
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      ConstraintsScope? capturedScope;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBuilder(
              compact: const Text('compact'),
              medium: Builder(
                builder: (context) {
                  capturedScope = ConstraintsScope.maybeOf(context);
                  return const Text('medium');
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedScope, isNotNull);
      expect(capturedScope!.windowClass, WindowSizeClass.expanded);
      expect(capturedScope!.localWidth, greaterThanOrEqualTo(840));
    });

    testWidgets('AdaptiveLayoutBuilder 子树中可读取 ConstraintsScope', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      ConstraintsScope? capturedScope;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveLayoutBuilder(
              compact: (_) => Builder(
                builder: (context) {
                  capturedScope = ConstraintsScope.maybeOf(context);
                  return const Text('medium');
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedScope, isNotNull);
      expect(capturedScope!.windowClass, WindowSizeClass.medium);
    });

    testWidgets('无 AdaptiveBuilder 时 ConstraintsScope.maybeOf 返回 null', (
      tester,
    ) async {
      ConstraintsScope? capturedScope;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedScope = ConstraintsScope.maybeOf(context);
              return const Text('no scope');
            },
          ),
        ),
      );

      expect(capturedScope, isNull);
    });
  });

  // ===================================================================
  // ResponsiveTokens.localSize 局部断点判定
  // ===================================================================
  group('ResponsiveTokens.localSize', () {
    testWidgets('在 expanded scope 中返回 expanded 值', (tester) async {
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBuilder(
              compact: const SizedBox(),
              medium: Builder(
                builder: (context) {
                  result = ResponsiveTokens.localSize(
                    context,
                    16,
                    medium: 24,
                    expanded: 32,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(result, 32);
    });

    testWidgets('在 medium scope 中返回 medium 值', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBuilder(
              compact: const SizedBox(),
              medium: Builder(
                builder: (context) {
                  result = ResponsiveTokens.localSize(
                    context,
                    16,
                    medium: 24,
                    expanded: 32,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(result, 24);
    });

    testWidgets('无 ConstraintsScope 时回退到全局 rsize', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? localResult;
      double? globalResult;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => Builder(
              builder: (context) {
                localResult = ResponsiveTokens.localSize(context, 16);
                globalResult = ResponsiveTokens.rsize(16);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(localResult, globalResult);
    });
  });

  // ===================================================================
  // P0-1 回归：全局 token medium 回退一致性
  // ===================================================================
  group('全局 token medium 回退一致性（P0-1 回归）', () {
    testWidgets(
      'medium 窗口 + medium=null + expanded=32 → 回退 compact（不跳 expanded）',
      (tester) async {
        // 700dp → medium 窗口
        tester.view.physicalSize = const Size(700, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        late double sizeResult;
        late double fontResult;
        late double rsizeResult;
        late double rfontResult;

        await tester.pumpWidget(
          MaterialApp(
            home: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, __) => Builder(
                builder: (context) {
                  sizeResult = ResponsiveTokens.size(16, expanded: 32);
                  fontResult = ResponsiveTokens.size(14, expanded: 28);
                  rsizeResult = ResponsiveTokens.rsize(16, expanded: 32);
                  rfontResult = ResponsiveTokens.rfont(14, expanded: 28);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        // 在 medium 窗口、medium=null 时，应回退到 compact 值而非 expanded
        expect(sizeResult, 16, reason: 'size: medium=null → compact 值');
        expect(fontResult, 14, reason: 'font: medium=null → compact 值');
        expect(
          rsizeResult,
          16,
          reason: 'rsize: medium=null → compact 值（medium 不缩放）',
        );
        expect(
          rfontResult,
          14,
          reason: 'rfont: medium=null → compact 值（medium 不缩放）',
        );
      },
    );

    testWidgets('medium 窗口 + medium=24 → 返回 medium 值', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late double sizeResult;
      late double rsizeResult;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => Builder(
              builder: (context) {
                sizeResult = ResponsiveTokens.size(
                  16,
                  medium: 24,
                  expanded: 32,
                );
                rsizeResult = ResponsiveTokens.rsize(
                  16,
                  medium: 24,
                  expanded: 32,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(sizeResult, 24);
      expect(rsizeResult, 24);
    });

    testWidgets('expanded 窗口 + expanded=null + medium=24 → 回退 medium', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late double sizeResult;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => Builder(
              builder: (context) {
                sizeResult = ResponsiveTokens.size(16, medium: 24);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(sizeResult, 24, reason: 'expanded=null → 回退 medium');
    });

    testWidgets('与 valueOf 行为一致', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late double tokenResult;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => Builder(
              builder: (context) {
                tokenResult = ResponsiveTokens.size(16, expanded: 32);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final valueOfResult = ResponsiveBreakpoints.valueOf<double>(
        const BoxConstraints(maxWidth: 700),
        compactValue: 16,
        expandedValue: 32,
      );

      expect(
        tokenResult,
        valueOfResult,
        reason: 'size() 和 valueOf() 在相同断点下应有相同回退行为',
      );
    });
  });

  // ===================================================================
  // P0-2 回归：localSize 大屏窄面板 compact 不缩放
  // ===================================================================
  group('localSize 大屏窄面板 compact 不缩放（P0-2 回归）', () {
    testWidgets('全局 expanded + 局部 compact → 返回固定 dp（不缩放）', (tester) async {
      // 全局 890dp（expanded），但 AdaptiveBuilder 的 compact 子树宽度 < 600
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => Scaffold(
              body: Row(
                children: [
                  const SizedBox(width: 300),
                  Expanded(
                    // 剩余 ~590dp < 600dp → 局部 compact
                    child: AdaptiveLayoutBuilder(
                      compact: (_) => Builder(
                        builder: (context) {
                          result = ResponsiveTokens.localSize(context, 16);
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 大屏窄面板 compact → 不缩放，直接返回 16.0
      expect(result, 16.0, reason: '大屏窄面板 compact 不缩放');
    });

    testWidgets('全局 compact + 局部 compact → 按设计稿缩放', (tester) async {
      // 全局 400dp（compact），局部也是 compact
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? localResult;
      double? globalResult;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => Scaffold(
              body: AdaptiveLayoutBuilder(
                compact: (_) => Builder(
                  builder: (context) {
                    localResult = ResponsiveTokens.localSize(context, 16);
                    globalResult = ResponsiveTokens.rsize(16);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // 真手机 compact → 缩放，与全局 rsize 一致
      expect(localResult, globalResult, reason: '真手机 compact 缩放与全局一致');
      expect(
        localResult,
        isNot(16.0),
        reason: '400/375 = 1.067 → 缩放结果应 ≠ 16.0',
      );
    });
  });

  // ===================================================================
  // ResponsiveTokens.localFont
  // ===================================================================
  group('ResponsiveTokens.localFont', () {
    testWidgets('在 expanded scope 中返回 expanded 值', (tester) async {
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBuilder(
              compact: const SizedBox(),
              medium: Builder(
                builder: (context) {
                  result = ResponsiveTokens.localFont(
                    context,
                    14,
                    medium: 16,
                    expanded: 18,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(result, 18);
    });

    testWidgets('在 medium scope 中返回 medium 值', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBuilder(
              compact: const SizedBox(),
              medium: Builder(
                builder: (context) {
                  result = ResponsiveTokens.localFont(
                    context,
                    14,
                    medium: 16,
                    expanded: 18,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(result, 16);
    });

    testWidgets('无 ConstraintsScope 时回退到全局 rfont', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? localResult;
      double? globalResult;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => Builder(
              builder: (context) {
                localResult = ResponsiveTokens.localFont(context, 14);
                globalResult = ResponsiveTokens.rfont(14);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(localResult, globalResult);
    });
  });

  // ===================================================================
  // LayoutSemantics
  // ===================================================================
  group('LayoutSemantics', () {
    test('railLabelType: expanded → all', () {
      expect(
        LayoutSemantics.railLabelType(const BoxConstraints(maxWidth: 900)),
        NavigationRailLabelType.all,
      );
    });

    test('railLabelType: medium → selected', () {
      expect(
        LayoutSemantics.railLabelType(const BoxConstraints(maxWidth: 700)),
        NavigationRailLabelType.selected,
      );
    });

    test('railLabelType: compact → selected', () {
      expect(
        LayoutSemantics.railLabelType(const BoxConstraints(maxWidth: 400)),
        NavigationRailLabelType.selected,
      );
    });

    test('masterPaneRatio: expanded → 0.35', () {
      expect(
        LayoutSemantics.masterPaneRatio(const BoxConstraints(maxWidth: 900)),
        0.35,
      );
    });

    test('masterPaneRatio: medium → 0.4', () {
      expect(
        LayoutSemantics.masterPaneRatio(const BoxConstraints(maxWidth: 700)),
        0.4,
      );
    });
  });

  // ===================================================================
  // hasAsymmetricHorizontalPadding
  // ===================================================================
  group('hasAsymmetricHorizontalPadding', () {
    testWidgets('左右 padding 不同时返回 true', (tester) async {
      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(left: 0, right: 84),
            ),
            child: Builder(
              builder: (context) {
                result = context.hasAsymmetricHorizontalPadding;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('左右 padding 相同时返回 false', (tester) async {
      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Builder(
              builder: (context) {
                result = context.hasAsymmetricHorizontalPadding;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('无 padding 时返回 false', (tester) async {
      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = context.hasAsymmetricHorizontalPadding;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });
  });

  // ===================================================================
  // MyBottomNavigationBar 平台分支
  // ===================================================================
  group('MyBottomNavigationBar', () {
    const destinations = [
      (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
      (
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profile',
      ),
    ];

    testWidgets('iOS 平台渲染 CupertinoTabBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            bottomNavigationBar: MyBottomNavigationBar(
              currentIndex: 0,
              onTap: (_) {},
              destinations: destinations,
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Android 平台渲染 Material NavigationBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            bottomNavigationBar: MyBottomNavigationBar(
              currentIndex: 0,
              onTap: (_) {},
              destinations: destinations,
            ),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(CupertinoTabBar), findsNothing);
    });

    testWidgets('点击事件正确触发', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            bottomNavigationBar: MyBottomNavigationBar(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
              destinations: destinations,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Profile'));
      expect(tappedIndex, 1);
    });
  });

  // ===================================================================
  // 全局 Window 系列（windowValueOf / fromWindowSize / isCompactWindow）
  // ===================================================================
  group('全局 Window 系列', () {
    testWidgets('fromWindowSize: 700dp → medium', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late WindowSizeClass result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ResponsiveBreakpoints.fromWindowSize(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, WindowSizeClass.medium);
    });

    testWidgets('isCompactWindow: 400dp → true', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ResponsiveBreakpoints.isCompactWindow(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('windowValueOf: expanded 窗口回退行为', (tester) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late String result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ResponsiveBreakpoints.windowValueOf<String>(
                context,
                compactValue: 'compact',
                mediumValue: 'medium',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      // expanded 窗口 + expanded=null → 渐进回退到 medium
      expect(result, 'medium');
    });

    test('tryFromConstraints: 有界约束返回正确尺寸类', () {
      expect(
        ResponsiveBreakpoints.tryFromConstraints(
          const BoxConstraints(maxWidth: 700),
        ),
        WindowSizeClass.medium,
      );
    });

    test('tryFromConstraints: 无界约束返回 null', () {
      expect(
        ResponsiveBreakpoints.tryFromConstraints(const BoxConstraints()),
        isNull,
      );
    });
  });

  // ===================================================================
  // FoldAwareBuilder
  // ===================================================================
  group('FoldAwareBuilder', () {
    testWidgets('compact 宽度渲染 compact 回调', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoldAwareBuilder(
              compact: (_, fold) {
                return const Text('compact');
              },
              medium: (_, fold) => const Text('medium'),
            ),
          ),
        ),
      );

      expect(find.text('compact'), findsOneWidget);
      expect(find.text('medium'), findsNothing);
    });

    testWidgets('expanded 宽度回退到 medium', (tester) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoldAwareBuilder(
              compact: (_, __) => const Text('compact'),
              medium: (_, __) => const Text('medium'),
            ),
          ),
        ),
      );

      // expanded 无 expanded 回调 → 回退 medium
      expect(find.text('medium'), findsOneWidget);
    });

    testWidgets('注入 ConstraintsScope 到子树', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      ConstraintsScope? scope;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoldAwareBuilder(
              compact: (_, __) => Builder(
                builder: (context) {
                  scope = ConstraintsScope.maybeOf(context);
                  return const Text('medium');
                },
              ),
            ),
          ),
        ),
      );

      expect(scope, isNotNull);
      expect(scope!.windowClass, WindowSizeClass.medium);
    });

    testWidgets('FoldInfo 从 displayFeatures 正确传递', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FoldInfo? capturedFold;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: FoldAwareBuilder(
                compact: (_, fold) {
                  capturedFold = fold;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedFold, isNotNull);
      expect(capturedFold!.isFoldable, isTrue);
      expect(capturedFold!.obstruction, const Rect.fromLTRB(440, 0, 450, 890));
    });
  });

  // ===================================================================
  // 外屏横持断点锁定（问题 11 行为锁定）
  // ===================================================================
  group('外屏横持断点行为锁定', () {
    testWidgets('完整窗口宽 678 → medium（已知限制，SafeArea 594 < 600）', (tester) async {
      // 锁定当前行为：断点基于完整窗口宽度。
      // 当 Flutter 官方明确「断点应扣 SafeArea inset」时，此测试需更新。
      tester.view.physicalSize = const Size(678, 466);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late WindowSizeClass result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ResponsiveBreakpoints.fromWindowSize(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        result,
        WindowSizeClass.medium,
        reason: '当前基于完整窗口宽度判定，678 ≥ 600 → medium',
      );
    });
  });
}
