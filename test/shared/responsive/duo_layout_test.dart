import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/fold_aware.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// iPhone Duo（2026）三形态逻辑尺寸：
/// - 折叠外屏：466 × 678（普通手机，compact）
/// - 展开横持：890 × 626（自然形态，expanded）
/// - 展开竖持：626 × 890（medium）
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===================================================================
  // 断点判定（含边界值）
  // ===================================================================
  group('断点判定', () {
    test('iPhone Duo 折叠外屏 466pt → compact', () {
      expect(ResponsiveBreakpoints.fromWidth(466), WindowSizeClass.compact);
    });

    test('展开竖持 626pt → medium', () {
      expect(ResponsiveBreakpoints.fromWidth(626), WindowSizeClass.medium);
    });

    test('展开横持 890pt → expanded', () {
      expect(ResponsiveBreakpoints.fromWidth(890), WindowSizeClass.expanded);
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

    testWidgets('700pt + 仅 compact+expanded → 回退 compact（不跳 expanded）',
        (tester) async {
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
  // StatefulAdaptiveBuilder：只构建实际不同的子树
  // ===================================================================
  group('StatefulAdaptiveBuilder', () {
    testWidgets('仅 compact+medium 时不重复挂载 medium', (tester) async {
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatefulAdaptiveBuilder(
              compact: Text('compact'),
              medium: Text('medium'),
            ),
          ),
        ),
      );

      // expanded 回退到 medium，应只找到一个 medium
      expect(find.text('medium'), findsOneWidget);
    });
  });

  // ===================================================================
  // Token clamp
  // ===================================================================
  group('Token clamp（防止大屏过度放大）', () {
    testWidgets('rw 在展开态 890pt clamp 到 1.2 倍上限', (tester) async {
      tester.view.physicalSize = const Size(890, 626);
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

      // 890/375 = 2.37, clamp 1.2 → 16 * 1.2 = 19.2
      expect(16.rw, closeTo(19.2, 0.01));
      expect(100.rw, closeTo(120, 0.01));
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

    testWidgets('hingeBounds 优先返回 obstruction', (tester) async {
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
                expect(fold.hingeBounds, fold.obstruction);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  // ===================================================================
  // HingeSplitLayout
  // ===================================================================
  group('HingeSplitLayout', () {
    testWidgets('无铰链时使用 fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HingeSplitLayout(
              left: Text('left'),
              right: Text('right'),
              fallback: Text('fallback'),
            ),
          ),
        ),
      );

      expect(find.text('fallback'), findsOneWidget);
      expect(find.text('left'), findsNothing);
      expect(find.text('right'), findsNothing);
    });

    testWidgets('有铰链时分成左右两侧', (tester) async {
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
              body: HingeSplitLayout(
                left: Text('left'),
                right: Text('right'),
                fallback: Text('fallback'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('left'), findsOneWidget);
      expect(find.text('right'), findsOneWidget);
      expect(find.text('fallback'), findsNothing);
    });

    testWidgets('铰链在本地约束之外（嵌套子面板）时回退 fallback', (tester) async {
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
            // 模拟嵌套在 400pt 宽的子面板中：铰链(440-450)完全在面板外
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  child: HingeSplitLayout(
                    left: Text('left'),
                    right: Text('right'),
                    fallback: Text('fallback'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('fallback'), findsOneWidget);
      expect(find.text('left'), findsNothing);
      expect(find.text('right'), findsNothing);
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
}
