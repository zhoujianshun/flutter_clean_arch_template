import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/shared/widgets/modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_clean_arch_template/shared/widgets/modal_bottom_sheet_selector/bottom_sheet_selector.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_alert_dialog.dart';

/// 对话框工具类
///
/// 提供统一的对话框和底部表单功能，替代原 RouteUtilDialog
///
/// 使用示例：
/// ```dart
/// // 显示自定义对话框
/// await DialogUtils.showModal(
///   builder: (context) => MyDialog(),
/// );
///
/// // 显示确认对话框
/// final confirmed = await DialogUtils.showConfirm(
///   title: '提示',
///   content: '确定要删除吗？',
/// );
///
/// // 显示底部表单
/// await DialogUtils.showBottomSheet(
///   builder: (context) => MyBottomSheet(),
/// );
/// ```
class DialogUtils {
  DialogUtils._();

  /// 全局导航键（需要在main.dart中设置）
  static GlobalKey<NavigatorState>? navigatorKey;

  /// 获取当前上下文
  static BuildContext? get _context => navigatorKey?.currentContext;

  // ===== 对话框相关 =====

  /// 显示模态对话框
  ///
  /// [builder] 对话框构建器
  /// [barrierDismissible] 是否可以通过点击背景关闭
  /// [barrierColor] 背景颜色
  /// [useSafeArea] 是否使用安全区域
  /// [resizeToAvoidBottomInset] 键盘弹出时是否上移，true:上移，false:不上移
  /// [routeSettings] 路由设置
  static Future<T?> showModal<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
    bool resizeToAvoidBottomInset = true,
  }) async {
    try {
      if (_context == null) {
        AppLogger.error('DialogUtils: Context is null, cannot show dialog');
        return null;
      }

      AppLogger.info('显示对话框');

      return MyDialogHelper.showMyDialog(
        context: _context!,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        useSafeArea: useSafeArea,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        routeSettings: routeSettings,
      );
    } catch (e, stackTrace) {
      AppLogger.error('显示对话框失败: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 显示警告对话框
  ///
  /// [title] 标题
  /// [content] 内容
  /// [cancelText] 取消按钮文本
  /// [confirmText] 确认按钮文本
  /// [onCancel] 取消回调
  /// [onConfirm] 确认回调
  static Future<bool?> showAlert({
    required String title,
    required String content,
    String? cancelText,
    String? confirmText,
    void Function(BuildContext context)? onCancel,
    void Function(BuildContext context)? onConfirm,
  }) {
    try {
      if (_context == null) {
        AppLogger.error('DialogUtils: Context is null, cannot show alert dialog');
        return Future.value();
      }

      AppLogger.info('显示警告对话框: $title');

      return showSimple(
        contentWidget: Text(content),
        title: title,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: (context) {
          onCancel?.call(context);
          Navigator.of(context).pop(false);
        },
        onConfirm: (context) {
          onConfirm?.call(context);
          Navigator.of(context).pop(true);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('显示警告对话框失败: $e', error: e, stackTrace: stackTrace);
      return Future.value();
    }
  }

  /// 显示简单对话框
  ///
  /// [contentWidget] 内容组件
  /// [title] 标题文本
  /// [titleWidget] 标题组件
  /// [cancelText] 取消按钮文本
  /// [confirmText] 确认按钮文本
  /// [onCancel] 取消回调
  /// [onConfirm] 确认回调
  /// [showCancelButton] 是否显示取消按钮
  /// [showConfirmButton] 是否显示确认按钮
  /// [contentPadding] 内容内边距
  /// [resizeToAvoidBottomInset] 键盘弹出时是否上移
  static Future<bool?> showSimple({
    required Widget contentWidget,
    String? title,
    Widget? titleWidget,
    String? cancelText,
    String? confirmText,
    void Function(BuildContext context)? onCancel,
    void Function(BuildContext context)? onConfirm,
    bool showCancelButton = true,
    bool showConfirmButton = true,
    EdgeInsets? contentPadding,
    bool resizeToAvoidBottomInset = true,
  }) async {
    try {
      if (_context == null) {
        AppLogger.error('DialogUtils: Context is null, cannot show simple dialog');
        return null;
      }

      AppLogger.info('显示简单对话框: $title');

      return MyDialogHelper.showSimpleDialog(
        context: _context!,
        contentWidget: contentWidget,
        title: title,
        titleWidget: titleWidget,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: onCancel,
        onConfirm: onConfirm,
        showCancelButton: showCancelButton,
        showConfirmButton: showConfirmButton,
        contentPadding: contentPadding,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    } catch (e, stackTrace) {
      AppLogger.error('显示简单对话框失败: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 显示确认对话框
  ///
  /// [title] 标题
  /// [content] 内容
  /// [confirmText] 确认按钮文本，默认"确定"
  /// [cancelText] 取消按钮文本，默认"取消"
  ///
  /// 返回值：用户点击确认返回 true，否则返回 false
  static Future<bool> showConfirm({
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
  }) async {
    final result = await showAlert(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
    );
    return result ?? false;
  }

  // ===== 底部表单相关 =====

  /// 显示底部表单
  ///
  /// [builder] 表单构建器
  /// [isScrollControlled] 是否可滚动控制
  /// [isDismissible] 是否可以通过下拉关闭
  /// [enableDrag] 是否启用拖拽
  /// [backgroundColor] 背景颜色
  /// [elevation] 阴影高度
  /// [shape] 形状
  /// [clipBehavior] 裁剪行为
  /// [routeSettings] 路由设置
  static Future<T?> showBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    RouteSettings? routeSettings,
  }) async {
    try {
      if (_context == null) {
        AppLogger.error('DialogUtils: Context is null, cannot show bottom sheet');
        return null;
      }

      AppLogger.info('显示底部表单');

      return MyModalBottomSheetHelper.showMyModalBottomSheet(
        context: _context!,
        builder: builder,
        isScrollControlled: isScrollControlled,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        clipBehavior: clipBehavior,
        routeSettings: routeSettings,
        shape: shape,
        backgroundColor: backgroundColor,
        elevation: elevation,
      );
    } catch (e, stackTrace) {
      AppLogger.error('显示底部表单失败: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 显示带标题的底部表单
  ///
  /// [builder] 表单构建器
  /// [title] 标题
  /// [useRootNavigator] 是否使用根导航器
  /// [isScrollControlled] 是否可滚动控制
  /// [enableDrag] 是否启用拖拽
  /// [isDismissible] 是否可关闭
  static Future<T?> showBottomSheetWithHeader<T>({
    required WidgetBuilder builder,
    required String title,
    bool useRootNavigator = true,
    bool isScrollControlled = false,
    bool enableDrag = true,
    bool isDismissible = true,
  }) {
    if (_context == null) {
      AppLogger.error('DialogUtils: Context is null, cannot show bottom sheet with header');
      return Future.value();
    }

    return MyModalBottomSheetHelper.showModalBottomSheetWithHeader<T>(
      context: _context!,
      builder: builder,
      title: title,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
    );
  }

  /// 显示底部选择器
  ///
  /// [actions] 选项列表
  /// [title] 标题
  /// [isDismissible] 是否可关闭
  /// [useRootNavigator] 是否使用根导航器
  static Future<T?> showBottomSheetSelector<T>({
    required List<BottomSelectorItem> actions,
    String? title,
    bool isDismissible = false,
    bool useRootNavigator = false,
  }) {
    if (_context == null) {
      AppLogger.error('DialogUtils: Context is null, cannot show bottom sheet selector');
      return Future.value();
    }

    return MyModalBottomSheetSelectorHelper.show<T>(
      _context!,
      actions: actions,
      title: title,
      isDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
    );
  }
}
