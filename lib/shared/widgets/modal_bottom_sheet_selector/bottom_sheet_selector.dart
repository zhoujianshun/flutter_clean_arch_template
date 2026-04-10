import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/widgets/modal_bottom_sheet/modal_bottom_sheet.dart';

class MyModalBottomSheetSelectorHelper {
  /// 显示底部选择器
  ///
  /// [context] 上下文
  /// [actions] 选择器选项列表
  /// [title] 选择器标题，可选
  /// [isDismissible] 是否可以通过点击遮罩关闭，默认为 false
  /// [useRootNavigator] 是否使用根导航器，默认为 false
  ///
  /// 返回用户选择的结果，如果用户取消则返回 null
  static Future<T?> show<T>(
    BuildContext context, {
    required List<BottomSelectorItem> actions,
    String? title,
    bool isDismissible = false,
    bool useRootNavigator = false,
  }) async {
    if (actions.isEmpty) {
      throw ArgumentError('选择器选项列表不能为空');
    }

    return MyModalBottomSheetHelper.showMyModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      isDismissible: isDismissible,
      builder: (ctx) {
        return BottomSheetSelector(
          actions: actions,
          title: title,
        );
      },
    );
  }
}

/// 底部选择器组件
///
/// 提供统一的底部选择器界面，支持多个选项和取消操作
/// 适用于需要用户从多个选项中选择一个的场景
class BottomSheetSelector extends StatelessWidget {
  const BottomSheetSelector({
    required this.actions,
    this.title,
    super.key,
  });

  /// 选择器选项列表
  final List<BottomSelectorItem> actions;

  /// 选择器标题，可选
  final String? title;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // 添加标题（如果存在）
    if (title != null) {
      children
        ..add(_buildHeader(context))
        ..add(const Divider(height: 1));
    }

    // 添加选项按钮
    for (final element in actions) {
      children
        ..add(
          _buildButton(
            context,
            element.title,
            element.onPressed,
            style: AppTextStyles.bodyMedium.copyWith(
              color: element.isDestructive
                  ? AppAdaptiveColors.error500(context)
                  : AppAdaptiveColors.neutral750(context),
              fontWeight: FontWeight.w500,
              fontFamily: AppTextStyles.fontFamilyMedium,
            ),
          ),
        )
        ..add(const Divider(height: 1));
    }

    // 移除最后一个分割线，添加底部间距和取消按钮
    children
      ..removeLast()
      ..addAll([
        // 底部间距
        Container(height: 8.w),
        // 取消按钮
        ColoredBox(
          color: AppAdaptiveColors.neutral100(context),
          child: SafeArea(
            top: false,
            child: _buildButton(context, '取消', (ctx) {
              Navigator.of(ctx).pop();
            }),
          ),
        ),
      ]);

    return Container(
      decoration: BoxDecoration(
        color: AppAdaptiveColors.neutral150(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  /// 构建选择器标题
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppAdaptiveColors.neutral100(context),
      alignment: Alignment.center,
      width: double.infinity,
      height: 54.w,
      child: FittedBox(
        child: Text(
          title ?? '',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppAdaptiveColors.neutral650(context),
          ),
        ),
      ),
    );
  }

  /// 构建选项按钮
  ///
  /// [context] 上下文
  /// [title] 按钮文本
  /// [onPressed] 点击回调
  /// [style] 文本样式，可选
  Widget _buildButton(
    BuildContext context,
    String title,
    void Function(BuildContext context) onPressed, {
    TextStyle? style,
  }) {
    return Container(
      color: AppAdaptiveColors.neutral100(context),
      width: double.infinity,
      child: TextButton(
        onPressed: () => onPressed(context),
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          minimumSize: WidgetStateProperty.all(Size(100.w, 54.w)),
        ),
        child: FittedBox(
          child: Text(
            title,
            style:
                style ??
                AppTextStyles.bodyMedium.copyWith(
                  color: AppAdaptiveColors.neutral750(context),
                ),
          ),
        ),
      ),
    );
  }
}

/// 底部选择器选项项
///
/// 定义选择器中的单个选项，包含标题、点击回调和是否为危险操作标识
class BottomSelectorItem {
  const BottomSelectorItem({
    required this.onPressed,
    required this.title,
    this.isDestructive = false,
  });

  /// 点击回调函数
  final void Function(BuildContext context) onPressed;

  /// 选项标题文本
  final String title;

  /// 是否为危险操作（如删除），会影响文本颜色
  final bool isDestructive;
}
