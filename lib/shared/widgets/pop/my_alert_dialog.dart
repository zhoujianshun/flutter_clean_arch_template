import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_filled_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_outlined_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/widgets/default_alert_title.dart';

/// 弹窗助手类
///
/// 提供统一的弹窗显示接口，包括简单弹窗和自定义弹窗
/// 适用于需要显示弹窗的场景，如提示、确认、选择等
class MyDialogHelper {
  /// 显示简单弹窗
  ///
  /// [context] 上下文
  /// [contentWidget] 内容组件
  /// [title] 标题
  /// [titleWidget] 标题组件
  /// [cancelText] 取消按钮文本
  /// [confirmText] 确认按钮文本
  /// [onCancel] 取消回调
  /// [onConfirm] 确认回调
  /// [showCancelButton] 是否显示取消按钮
  /// [showConfirmButton] 是否显示确认按钮
  /// [contentPadding] 内容边距
  /// [resizeToAvoidBottomInset] 是否适应底部键盘
  /// [T] 返回类型
  static Future<T?> showSimpleDialog<T>({
    required BuildContext context,
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
  }) {
    return showMyDialog(
      context: context,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      builder: (context) => PopScope(
        // 禁止返回,手势返回无效
        canPop: false,
        // onPopInvokedWithResult: (didPop, result) {
        //   if (didPop) {
        //     Navigator.of(context).pop(result);
        //   }
        // },
        child: MySimpleDialog(
          title: title,
          titleWidget: titleWidget,
          cancelText: cancelText,
          confirmText: confirmText,
          onCancel: onCancel,
          onConfirm: onConfirm,
          showCancelButton: showCancelButton,
          showConfirmButton: showConfirmButton,
          contentPadding: contentPadding,
          contentWidget: contentWidget,
        ),
      ),
    );
  }

  /// 自定义弹出容器样式
  static Future<T?> showMyDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool useRootNavigator = true,
    bool barrierDismissible = false,
    Color? barrierColor,
    bool useSafeArea = true,

    /// 键盘弹出时弹窗不上移,true:上移,false:不上移
    bool resizeToAvoidBottomInset = true,
    RouteSettings? routeSettings,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewInsets: resizeToAvoidBottomInset ? MediaQuery.of(context).viewInsets : EdgeInsets.zero,
        ),
        child: builder(context),
      ),
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      routeSettings: routeSettings,
    );
  }
}

/// 自定义弹出容器样式，有标题和底部按钮
class MySimpleDialog extends StatelessWidget {
  const MySimpleDialog({
    required this.contentWidget,
    this.content,
    super.key,
    this.title,
    this.titleWidget,
    this.cancelText,
    this.confirmText,
    this.onCancel,
    this.onConfirm,
    this.showCancelButton = true,
    this.showConfirmButton = true,
    this.contentPadding,
  });

  final EdgeInsets? contentPadding;
  final String? title;
  final String? content;
  final Widget? titleWidget;
  final Widget? contentWidget;
  final String? cancelText;
  final String? confirmText;
  final void Function(BuildContext context)? onCancel;
  final void Function(BuildContext context)? onConfirm;
  final bool showCancelButton;
  final bool showConfirmButton;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      // title:,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      children: [
        Stack(
          children: [
            Column(
              children: [
                _buildTitle(context),
                _buildContent(context),
                ..._buildBottomButtons(context),
              ],
            ),
            _buildCloseButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: contentPadding ?? EdgeInsets.only(top: 24.w, left: 32.w, right: 32.w, bottom: 24.w),
      child: contentWidget ?? Text(content ?? '', style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (titleWidget != null) {
      return titleWidget!;
    }
    if (title == null) {
      return 32.verticalSpaceFromWidth;
    }
    return DefaultAlertTitle(title: title ?? '');
  }

  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 0.w,
      right: 0.w,
      child: MyButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Container(
          width: 40.w,
          height: 40.w,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/circle_gray_close_icon.svg',
            width: 24.w,
            height: 24.w,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBottomButtons(BuildContext context) {
    final bottomButtons = <Widget>[];
    final btnWidth = showCancelButton && showConfirmButton ? null : 140.w;
    if (showCancelButton) {
      final btn = MyOutlinedButton.roundText(
        minimumSize: Size(btnWidth ?? 0, 40.w),
        expand: true,
        padding: EdgeInsets.zero,
        type: MyOutlinedButtonType.plain,
        onPressed: () => _handleCancel(context),
        text: cancelText ?? '取消',
      );

      bottomButtons.add(
        btnWidth == null
            ? Expanded(
                child: btn,
              )
            : btn,
      );
    }
    if (showConfirmButton) {
      final btn = MyFilledButton.roundText(
        minimumSize: Size(btnWidth ?? 0, 40.w),
        padding: EdgeInsets.zero,
        onPressed: () => onConfirm?.call(context),
        text: confirmText ?? '确定',
      );
      bottomButtons.add(
        btnWidth == null
            ? Expanded(
                child: btn,
              )
            : btn,
      );
    }

    final bottomButtonsWidget = bottomButtons.isNotEmpty
        ? [
            const Divider(
              height: 1,
            ),
            12.verticalSpaceFromWidth,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8.w,
              children: [16.w.horizontalSpace, ...bottomButtons, 16.w.horizontalSpace],
            ),
            12.verticalSpaceFromWidth,
          ]
        : <Widget>[];

    return bottomButtonsWidget;
  }

  void _handleCancel(BuildContext context) {
    if (onCancel != null) {
      onCancel!(context);
    } else {
      Navigator.of(context).pop();
    }
  }
}

// class MyTextAction {
//   MyTextAction({
//     required this.title,
//     required this.onPressed,
//     this.isDefaultAction = false,
//     this.isDestructiveAction = false,
//   });

//   /// The callback that is called when the button is tapped or otherwise
//   /// activated.
//   ///
//   /// If this is set to null, the button will be disabled.
//   final VoidCallback? onPressed;

//   /// Set to true if button is the default choice in the dialog.
//   ///
//   /// Default buttons have bold text. Similar to
//   /// [UIAlertController.preferredAction](https://developer.apple.com/documentation/uikit/uialertcontroller/1620102-preferredaction),
//   /// but more than one action can have this attribute set to true in the same
//   /// [CupertinoAlertDialog].
//   ///
//   /// This parameters defaults to false and cannot be null.
//   final bool isDefaultAction;

//   /// Whether this action destroys an object.
//   ///
//   /// For example, an action that deletes an email is destructive.
//   ///
//   /// Defaults to false and cannot be null.
//   final bool isDestructiveAction;
//   final String title;
// }

// /// 自定义AlertDialog，自定义风格
// class MyAlertDialog extends AlertDialog {
//   // final String? title;
//   // final String? content;
//   // final List<String> actionTitles;

//   MyAlertDialog({
//     super.key,
//     String? title,
//     String? content,
//     Widget? contentWidget,
//     List<MyTextAction>? actionTitles,
//   }) : super(
//             title: title != null ? Text(title) : null,
//             content: contentWidget ??
//                 (content != null
//                     ? _DialogContent(
//                         content: content,
//                       )
//                     : null),
//             actions: actionTitles != null
//                 ? actionTitles.map((item) {
//                     return CupertinoDialogAction(
//                       isDefaultAction: item.isDefaultAction,
//                       isDestructiveAction: item.isDestructiveAction,
//                       onPressed: item.onPressed,
//                       child: Text(item.title),
//                     );
//                   }).toList()
//                 : []);

//   // MyAlertDialog({
//   //   Key? key,
//   //   String? title,
//   //   String? content,
//   //   List<String>? actionTitles,
//   //   Function(int)? actionCallback,
//   // }) : super(
//   //           key: key,
//   //           title: title != null ? Text(title) : null,
//   //           content: content != null
//   //               ? _DialogContent(
//   //                   content: content,
//   //                 )
//   //               : null,
//   //           actions: actionTitles != null
//   //               ? actionTitles.map((item) {
//   //                   final index = actionTitles.indexOf(item);
//   //                   return CupertinoDialogAction(
//   //                     child: Text(item),
//   //                     onPressed: () {
//   //                       if (actionCallback != null) {
//   //                         actionCallback(index);
//   //                       }
//   //                     },
//   //                   );
//   //                 }).toList()
//   //               : []);

//   static Future<T?> showAlert<T>({
//     required BuildContext context,
//     required String content,
//     String title = '提示',
//     List<MyTextAction>? actionTitles,
//   }) {
//     return myShowDialog<T>(
//       context: context,
//       builder: (context) => MyCupertinoAlertDialog(
//         title: title,
//         content: content,
//         actionTitles: actionTitles,
//       ),
//     );
//   }

//   static Future<T?> showAlertWithContentWidget<T>({
//     required BuildContext context,
//     required Widget contentWidget,
//     String? title,
//     List<MyTextAction>? actionTitles,
//   }) {
//     return myShowDialog<T>(
//       context: context,
//       builder: (context) => MyCupertinoAlertDialog(
//         title: title,
//         contentWidget: contentWidget,
//         actionTitles: actionTitles,
//       ),
//     );
//   }

//   static void dismiss<T>(BuildContext context, [T? result]) {
//     Navigator.of(context).pop(result);
//   }
// }

// class _DialogContent extends StatelessWidget {
//   const _DialogContent({
//     required this.content,
//     super.key,
//   });
//   final String content;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.zero,
//       child: Text(content),
//     );
//     // return Padding(
//     //   padding: const EdgeInsets.only(top: 10),
//     //   child: SingleChildScrollView(
//     //     child: Text(content),
//     //   ),
//     // );
//   }
// }

/*


  Future<void> _showDeleteHistoryDialog2(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This is a demo alert dialog.'),
                Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                context.read<SearchHistoryViewModel>().deleteAll();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteHistoryDialog1(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This is a demo alert dialog.'),
                Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



* */
