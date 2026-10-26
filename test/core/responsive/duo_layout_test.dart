import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/core/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/core/responsive/fold_aware.dart';
import 'package:flutter_clean_arch_template/core/responsive/layout_semantics.dart';
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

  // 每个测试前清理全局状态
  setUp(ResponsiveBreakpoints.unboundedWarningHashes.clear);

  // ===================================================================
  // 断点判定（含边界值）
  // ===================================================================
  group('断点判定', () {
    test('iPhone Duo 折叠外屏 466pt → compact', () {
      expect(ResponsiveBreakpoints.fromWidth(466), WindowSizeClass.compact);
    });

    test('外屏横持 完整窗口宽 678pt → medium（已知限制：SafeArea 594 < 600）', () {
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

    testWidgets('无限宽度约束回退为 compact', (tester) async {
      // fromConstraints 对无界宽度会通过 FlutterError.reportError 发出静默警告，
      // 测试框架会捕获它，需要手动消费。
      final previousHandler = FlutterError.onError;
      FlutterError? capturedError;
      FlutterError.onError = (details) =>
          capturedError = details.exception as FlutterError;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              const unbounded = BoxConstraints();
              expect(
                ResponsiveBreakpoints.fromConstraints(context, unbounded),
                WindowSizeClass.compact,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      FlutterError.onError = previousHandler;
      expect(capturedError, isNotNull);
      expect(capturedError.toString(), contains('无界宽度约束'));
    });
  });

  // ===================================================================
  // BreakpointConfig 接线
  // ===================================================================
  group('BreakpointConfig', () {
    test('classify 使用自定义断点', () {
      const config = BreakpointConfig(
        compactBreakpoint: 700,
        expandedBreakpoint: 1000,
        child: SizedBox.shrink(),
      );
      expect(config.classify(650), WindowSizeClass.compact);
      expect(config.classify(700), WindowSizeClass.medium);
      expect(config.classify(999), WindowSizeClass.medium);
      expect(config.classify(1000), WindowSizeClass.expanded);
    });

    test('倒置阈值触发构造断言', () {
      // 注意：必须用非 const 调用（const 上下文中断言失败是编译期错误）。
      expect(
        () => BreakpointConfig(
          compactBreakpoint: 900,
          expandedBreakpoint: 600,
          child: const SizedBox.shrink(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('注入自定义 Config 后 AdaptiveBuilder 使用新断点', (tester) async {
      tester.view.physicalSize = const Size(650, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 默认断点：650 ≥ 600 → medium
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveBuilder(
              compact: Text('compact'),
              medium: Text('medium'),
            ),
          ),
        ),
      );
      expect(find.text('medium'), findsOneWidget);

      // 自定义断点：compact 700 → 650 < 700 → compact
      await tester.pumpWidget(
        const MaterialApp(
          home: BreakpointConfig(
            compactBreakpoint: 700,
            child: Scaffold(
              body: AdaptiveBuilder(
                compact: Text('compact'),
                medium: Text('medium'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('compact'), findsOneWidget);
    });

    testWidgets('注入自定义 Config 后 fromWindowSize 使用新断点', (tester) async {
      tester.view.physicalSize = const Size(650, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late WindowSizeClass result;

      await tester.pumpWidget(
        MaterialApp(
          home: BreakpointConfig(
            compactBreakpoint: 700,
            child: Builder(
              builder: (context) {
                result = ResponsiveBreakpoints.fromWindowSize(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(
        result,
        WindowSizeClass.compact,
        reason: '自定义 compact 700 → 650 < 700 → compact',
      );
    });

    testWidgets('of 无 Config 时使用默认值', (tester) async {
      late BreakpointConfig config;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              config = BreakpointConfig.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(config.compactBreakpoint, ResponsiveBreakpoints.compact);
      expect(config.expandedBreakpoint, ResponsiveBreakpoints.expanded);
    });

    testWidgets('注入自定义 Config 后 fromConstraints 使用新断点', (tester) async {
      tester.view.physicalSize = const Size(650, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late WindowSizeClass result;

      await tester.pumpWidget(
        MaterialApp(
          home: BreakpointConfig(
            compactBreakpoint: 700,
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  result = ResponsiveBreakpoints.fromConstraints(
                    context,
                    constraints,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(
        result,
        WindowSizeClass.compact,
        reason: '自定义 compact 700 → 650 < 700 → compact',
      );
    });
  });

  // ===================================================================
  // 渐进回退链（medium 缺失时不跳到 expanded）
  // ===================================================================
  group('渐进回退（valueOf）', () {
    testWidgets('medium 宽度、仅传 compact → 回退 compact', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveBreakpoints.valueOf(
                context,
                const BoxConstraints(maxWidth: 700),
                compactValue: 'compact',
              );
              expect(result, 'compact');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('medium 宽度、传 compact+expanded → 回退 compact（不跳 expanded）', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveBreakpoints.valueOf(
                context,
                const BoxConstraints(maxWidth: 700),
                compactValue: 'compact',
                expandedValue: 'expanded',
              );
              expect(result, 'compact');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('expanded 宽度、仅传 compact+medium → 回退 medium', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveBreakpoints.valueOf(
                context,
                const BoxConstraints(maxWidth: 900),
                compactValue: 'compact',
                mediumValue: 'medium',
              );
              expect(result, 'medium');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('expanded 宽度、仅传 compact → 回退 compact', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveBreakpoints.valueOf(
                context,
                const BoxConstraints(maxWidth: 900),
                compactValue: 'compact',
              );
              expect(result, 'compact');
              return const SizedBox();
            },
          ),
        ),
      );
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
  // ScreenUtil 防御与等价性
  //（本组必须位于所有 ScreenUtilInit 用例之前：ScreenUtil 单例一旦被
  //  configure 即无法重置，「未初始化回退」用例依赖单例尚未初始化）
  // ===================================================================
  group('ScreenUtil 防御与等价性', () {
    setUp(ResponsiveTokens.screenUtilMissingWarningHashes.clear);

    testWidgets('space 不依赖 ScreenUtilInit，按 MediaQuery 宽度缩放', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      // 注意：不包 ScreenUtilInit——space 的 compact 缩放应完全可用。
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ResponsiveTokens.of(context).space(16);
              return const SizedBox();
            },
          ),
        ),
      );

      // 400/375 = 1.067 → 16 * 1.067 ≈ 17.07
      expect(result, closeTo(16 * (400 / 375), 0.01));
    });

    testWidgets('font 未初始化 ScreenUtil 时回退固定 dp 且不抛异常', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      // 注意：不包 ScreenUtilInit——font 应安全回退而非抛
      // LateInitializationError。
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ResponsiveTokens.of(context).font(14);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, 14.0, reason: 'ScreenUtil 未初始化时 font 应回退固定 dp');
    });

    testWidgets('font 在 ScreenUtilInit 下正常缩放', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      // 不配 fontSizeResolver、minTextAdapt 默认 false
      // → scaleText = scaleWidth = 400/375。
      // 本用例位于「未初始化」用例之后，单例已由自身包裹的
      // ScreenUtilInit 完成 configure。
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => Builder(
              builder: (context) {
                result = ResponsiveTokens.of(context).font(14);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, closeTo(14 * (400 / 375), 0.01));
    });
  });

  // ===================================================================
  // Token clamp
  // ===================================================================
  group('Token clamp（防止大屏过度放大）', () {
    testWidgets('space 在 compact 窗口按设计稿缩放并 clamp', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => Builder(
              builder: (context) {
                result = ResponsiveTokens.of(context).space(16);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // 430/375 = 1.147, clamp 1.15 → 16 * 1.147 ≈ 18.35
      expect(result, closeTo(16 * (430 / 375), 0.01));
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

  // ===================================================================
  // FoldInfo == / hashCode / toString
  // ===================================================================
  group('FoldInfo 相等性与 toString', () {
    test('none == none', () {
      expect(FoldInfo.none, equals(FoldInfo.none));
    });

    test('相同 obstruction 的实例相等', () {
      const a = FoldInfo(obstruction: Rect.fromLTRB(440, 0, 450, 890));
      const b = FoldInfo(obstruction: Rect.fromLTRB(440, 0, 450, 890));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('不同 obstruction 的实例不相等', () {
      const a = FoldInfo(obstruction: Rect.fromLTRB(440, 0, 450, 890));
      const b = FoldInfo(obstruction: Rect.fromLTRB(300, 0, 310, 890));
      expect(a, isNot(equals(b)));
    });

    test('none toString', () {
      expect(FoldInfo.none.toString(), 'FoldInfo.none');
    });

    test('有铰链的 toString', () {
      const fold = FoldInfo(obstruction: Rect.fromLTRB(440, 0, 450, 890));
      final str = fold.toString();
      expect(str, contains('FoldInfo('));
      expect(str, contains('obstruction'));
      expect(str, contains('axis: vertical'));
    });
  });

  // ===================================================================
  // FoldAxis 推导
  // ===================================================================
  group('FoldAxis 推导', () {
    test('垂直铰链（height > width）→ vertical', () {
      const fold = FoldInfo(obstruction: Rect.fromLTRB(440, 0, 450, 890));
      expect(fold.axis, FoldAxis.vertical);
    });

    test('水平铰链（width > height）→ horizontal', () {
      const fold = FoldInfo(obstruction: Rect.fromLTRB(0, 440, 890, 450));
      expect(fold.axis, FoldAxis.horizontal);
    });

    test('无铰链/折痕 → null', () {
      expect(FoldInfo.none.axis, isNull);
    });

    test('折痕也可推导轴向', () {
      const fold = FoldInfo(foldCrease: Rect.fromLTRB(312, 0, 314, 890));
      expect(fold.axis, FoldAxis.vertical);
    });

    test('features 列表保留过滤后的 hinge/fold', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final fold = FoldInfo(obstruction: hinge.bounds, features: const [hinge]);
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

    testWidgets('垂直铰链分栏使用 Expanded 吸收浮点误差', (tester) async {
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

      // second pane 应使用 Expanded 而非固定 SizedBox
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.last, isA<Expanded>());
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
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: SizedBox(
                width: 890,
                height: 890,
                child: HingePaneLayout(
                  first: Text('top'),
                  second: Text('bottom'),
                  fallback: Text('fallback'),
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

    testWidgets('分栏后子树的 displayFeatures 被清除', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      List<DisplayFeature>? childFeatures;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              body: HingePaneLayout(
                first: Builder(
                  builder: (context) {
                    childFeatures = MediaQuery.displayFeaturesOf(context);
                    return const Text('first');
                  },
                ),
                second: const Text('second'),
                fallback: const Text('fallback'),
              ),
            ),
          ),
        ),
      );

      expect(childFeatures, isNotNull);
      expect(childFeatures, isEmpty, reason: '分栏后子树不应再看到铰链');
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
      expect(
        capturedFold!.isFoldable,
        isFalse,
        reason: '嵌套场景应收到 FoldInfo.none',
      );
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
      expect(capturedFold!.isFoldable, isTrue, reason: '全窗口场景应正常传递 FoldInfo');
    });
  });

  // ===================================================================
  // FoldAwareBuilder 轴向保护
  // ===================================================================
  group('FoldAwareBuilder 轴向保护', () {
    testWidgets('全宽半高 + 垂直铰链 → 正常传递（Scaffold body 场景）', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(440, 0, 450, 890),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FoldInfo? capturedFold;

      // Scaffold body 被 AppBar + bottomNavigationBar 压缩高度，
      // 但宽度覆盖完整窗口：垂直铰链（左右分栏依赖横向对齐）仍可用。
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              appBar: AppBar(title: const Text('app')),
              bottomNavigationBar: const SizedBox(height: 80),
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
      expect(capturedFold!.isFoldable, isTrue, reason: '宽度覆盖完整窗口，垂直铰链信息应正常传递');
    });

    testWidgets('全宽半高 + 水平铰链 → 降级 FoldInfo.none', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(0, 440, 890, 450),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FoldInfo? capturedFold;

      // 水平铰链（上下分栏）依赖纵向覆盖，body 高度 < 窗口高 → 全局坐标不可用。
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(890, 890),
              displayFeatures: [hinge],
            ),
            child: Scaffold(
              appBar: AppBar(title: const Text('app')),
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
      expect(
        capturedFold!.isFoldable,
        isFalse,
        reason: '高度未覆盖完整窗口，水平铰链应降级为 none',
      );
    });

    testWidgets('全高半宽 + 水平铰链 → 正常传递', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(0, 440, 890, 450),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      tester.view.physicalSize = const Size(890, 890);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FoldInfo? capturedFold;

      // 左侧留白 200，右列高度覆盖完整窗口：水平铰链坐标可用。
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
                    child: SizedBox(
                      height: 890,
                      child: FoldAwareBuilder(
                        compact: (_, fold) {
                          capturedFold = fold;
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

      expect(capturedFold, isNotNull);
      expect(capturedFold!.isFoldable, isTrue, reason: '高度覆盖完整窗口，水平铰链信息应正常传递');
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
  // ResponsiveTokens.of（推荐 API）
  // ===================================================================
  group('ResponsiveTokens.of', () {
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
                  final tokens = ResponsiveTokens.of(context);
                  result = tokens.space(16, medium: 24, expanded: 32);
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
                  final tokens = ResponsiveTokens.of(context);
                  result = tokens.space(16, medium: 24, expanded: 32);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(result, 24);
    });

    testWidgets('无 ConstraintsScope 时使用全局窗口宽度', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final tokens = ResponsiveTokens.of(context);
              result = tokens.fixedSize(16, medium: 24, expanded: 32);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(result, 24, reason: '700dp → medium → 返回 medium 值');
    });

    testWidgets('font 方法在 expanded 中返回固定 dp', (tester) async {
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
                  final tokens = ResponsiveTokens.of(context);
                  result = tokens.font(14, medium: 16, expanded: 18);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(result, 18);
    });
  });

  // ===================================================================
  // P0-2 回归：大屏窄面板 compact 不缩放
  // ===================================================================
  group('大屏窄面板 compact 不缩放（P0-2 回归）', () {
    testWidgets('全局 expanded + 局部 compact → 返回固定 dp（不缩放）', (tester) async {
      tester.view.physicalSize = const Size(890, 626);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => Scaffold(
              body: Row(
                children: [
                  const SizedBox(width: 300),
                  Expanded(
                    child: AdaptiveLayoutBuilder(
                      compact: (_) => Builder(
                        builder: (context) {
                          final tokens = ResponsiveTokens.of(context);
                          result = tokens.space(16);
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

      expect(result, 16.0, reason: '大屏窄面板 compact 不缩放');
    });

    testWidgets('全局 compact + 局部 compact → 按设计稿缩放', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => Scaffold(
              body: AdaptiveLayoutBuilder(
                compact: (_) => Builder(
                  builder: (context) {
                    final tokens = ResponsiveTokens.of(context);
                    result = tokens.space(16);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(result, isNot(16.0), reason: '400/375 = 1.067 → 缩放结果应 ≠ 16.0');
    });
  });

  // ===================================================================
  // LayoutSemantics（带 context 参数）
  // ===================================================================
  group('LayoutSemantics', () {
    testWidgets('railLabelType: expanded → all', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = LayoutSemantics.railLabelType(
                context,
                const BoxConstraints(maxWidth: 900),
              );
              expect(result, NavigationRailLabelType.all);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('railLabelType: medium → selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = LayoutSemantics.railLabelType(
                context,
                const BoxConstraints(maxWidth: 700),
              );
              expect(result, NavigationRailLabelType.selected);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('railLabelType: compact → selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = LayoutSemantics.railLabelType(
                context,
                const BoxConstraints(maxWidth: 400),
              );
              expect(result, NavigationRailLabelType.selected);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('masterPaneRatio: expanded → 0.35', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = LayoutSemantics.masterPaneRatio(
                context,
                const BoxConstraints(maxWidth: 900),
              );
              expect(result, 0.35);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('masterPaneRatio: medium → 0.4', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = LayoutSemantics.masterPaneRatio(
                context,
                const BoxConstraints(maxWidth: 700),
              );
              expect(result, 0.4);
              return const SizedBox();
            },
          ),
        ),
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
            data: const MediaQueryData(padding: EdgeInsets.only(right: 84)),
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
  // 全局 Window 系列
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

    testWidgets('context.isCompactWindow: 400dp → true', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = context.isCompactWindow;
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

      expect(result, 'medium');
    });

    testWidgets('tryFromConstraints: 有界约束返回正确尺寸类', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                ResponsiveBreakpoints.tryFromConstraints(
                  context,
                  const BoxConstraints(maxWidth: 700),
                ),
                WindowSizeClass.medium,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('tryFromConstraints: 无界约束返回 null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                ResponsiveBreakpoints.tryFromConstraints(
                  context,
                  const BoxConstraints(),
                ),
                isNull,
              );
              return const SizedBox();
            },
          ),
        ),
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
              compact: (_, _) => const Text('compact'),
              medium: (_, _) => const Text('medium'),
            ),
          ),
        ),
      );

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
              compact: (_, _) => Builder(
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
  // 外屏横持断点锁定
  // ===================================================================
  group('外屏横持断点行为锁定', () {
    testWidgets('完整窗口宽 678 → medium（已知限制，SafeArea 594 < 600）', (tester) async {
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
