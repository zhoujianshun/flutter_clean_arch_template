import 'package:flutter/widgets.dart';
import 'package:flutter_clean_arch_template/core/responsive/breakpoints.dart';

/// 向子树注入当前 [LayoutBuilder] 约束和窗口尺寸类。
///
/// 由 `AdaptiveBuilder` / `AdaptiveLayoutBuilder`
/// 在 [LayoutBuilder] 回调内自动注入，无需手动创建。
///
/// 子树中的组件可通过 [ConstraintsScope.of] 读取**局部**约束宽度，
/// 用于比全局 `ScreenUtil` 更精确的断点判定（如 NavigationRail 旁的内容面板、
/// iPhone Duo Split View 中的半屏窗口等）。
///
/// ```dart
/// // 在 AdaptiveBuilder 的子树中
/// final scope = ConstraintsScope.of(context);
/// final isLocallyCompact = scope.windowClass == WindowSizeClass.compact;
/// ```
class ConstraintsScope extends InheritedWidget {
  const ConstraintsScope({
    required this.constraints,
    required this.windowClass,
    required super.child,
    super.key,
  });

  /// 当前子树的父级约束。
  final BoxConstraints constraints;

  /// 基于 [constraints] 计算的窗口尺寸类。
  final WindowSizeClass windowClass;

  /// 当前子树的可用宽度（`constraints.maxWidth`）。
  ///
  /// 无界宽度时返回 [double.infinity]，调用方应处理此情况。
  double get localWidth =>
      constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity;

  /// 从最近的祖先读取，不存在时抛出 [FlutterError]。
  ///
  /// 如需安全访问，请使用 [maybeOf]。
  static ConstraintsScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ConstraintsScope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary('ConstraintsScope.of() called without a ConstraintsScope ancestor.'),
        ErrorDescription(
          'No ConstraintsScope was found in the widget tree above this context. '
          'ConstraintsScope is automatically injected by AdaptiveBuilder, '
          'AdaptiveLayoutBuilder, or FoldAwareBuilder.',
        ),
        ErrorHint(
          'Ensure the widget calling ConstraintsScope.of() is inside an '
          'AdaptiveBuilder or AdaptiveLayoutBuilder subtree, '
          'or use ConstraintsScope.maybeOf() for a nullable result.',
        ),
        context.describeElement('The context used was'),
      ]);
    }
    return scope;
  }

  /// 从最近的 [ConstraintsScope] 祖先读取，不存在时返回 null。
  static ConstraintsScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConstraintsScope>();
  }

  @override
  bool updateShouldNotify(ConstraintsScope oldWidget) {
    // windowClass 由 constraints 派生，constraints 不变时必相同，无需单独比较。
    return constraints != oldWidget.constraints;
  }
}
