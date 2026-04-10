import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/widgets/modal_bottom_sheet/bottom_sheet_header.dart';

class MyModalBottomSheetHelper {
  /// 自定义底部表单工具类
  ///
  /// 提供统一的底部表单显示接口，支持自定义样式和行为
  /// 基于 Flutter 原生 showModalBottomSheet 进行封装

  /// 显示自定义底部表单
  ///
  /// [context] 上下文
  /// [builder] 内容构建器
  /// [useRootNavigator] 是否使用根导航器，默认为 true
  /// [isScrollControlled] 是否支持滚动控制，默认为 false
  /// [useSafeArea] 是否使用安全区域，默认为 false
  /// [enableDrag] 是否可以通过下拉关闭，默认为 false
  /// [isDismissible] 是否可以通过返回键或点击遮罩关闭，默认为 false
  ///
  /// 返回用户操作的结果，如果用户取消则返回 null
  static Future<T?> showMyModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool useRootNavigator = true,
    bool isScrollControlled = false,
    bool useSafeArea = false,
    bool enableDrag = false,
    bool isDismissible = false,
    Clip? clipBehavior,
    RouteSettings? routeSettings,
    ShapeBorder? shape,
    Color? backgroundColor,
    double? elevation,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      routeSettings: routeSettings,
      elevation: elevation,
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      backgroundColor: backgroundColor ?? AppAdaptiveColors.neutral100(context),
      shape:
          shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
      builder: (context) => PopScope(
        // 根据 isDismissible 参数控制是否可以通过返回键关闭
        canPop: isDismissible,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: builder(context),
        ),
      ),
    );
  }

  /// 显示带标题的底部表单
  ///
  /// 在基础底部表单的基础上添加了标题头部，提供更好的用户体验
  ///
  /// [context] 上下文
  /// [builder] 内容构建器
  /// [title] 表单标题
  /// [useRootNavigator] 是否使用根导航器，默认为 true
  /// [isScrollControlled] 是否支持滚动控制，默认为 false
  /// [enableDrag] 是否可以通过下拉关闭，默认为 true
  /// [isDismissible] 是否可以通过返回键或点击遮罩关闭，默认为 true
  ///
  /// 返回用户操作的结果，如果用户取消则返回 null
  static Future<T?> showModalBottomSheetWithHeader<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    required String title,
    bool useRootNavigator = true,
    bool isScrollControlled = false,
    bool enableDrag = true,
    bool isDismissible = true,
  }) {
    return showMyModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      builder: (context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(title: title),
              Flexible(
                child: builder(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
