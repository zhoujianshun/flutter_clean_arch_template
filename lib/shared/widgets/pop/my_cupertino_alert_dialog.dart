import 'package:flutter/cupertino.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

/// 苹果风格弹窗助手类
///
/// 提供统一的苹果风格弹窗显示接口，包括提示、确认、选择等
class MyCupertinoDialogHelper {
  /// 自定义弹出容器样式，去除黑色蒙版，苹果风格
  static Future<T?> showMyCupertinoDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool useRootNavigator = true,
    bool barrierDismissible = false,
    RouteSettings? routeSettings,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      builder: builder,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      routeSettings: routeSettings,
    );
  }

  /// 显示提示弹窗
  ///
  /// [context] 上下文
  /// [content] 内容
  /// [title] 标题
  /// [actionTitles] 操作标题
  /// [T] 返回类型
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required String content,
    String title = '提示',
    List<MyTextAction>? actionTitles,
  }) {
    return showMyCupertinoDialog<T>(
      context: context,
      builder: (context) => MyCupertinoAlertDialog(
        title: title,
        content: content,
        actionTitles: actionTitles,
      ),
    );
  }

  /// 显示提示弹窗，带内容组件
  ///
  /// [context] 上下文
  /// [contentWidget] 内容组件
  /// [title] 标题
  /// [actionTitles] 操作标题
  /// [T] 返回类型
  static Future<T?> showDialogWithContentWidget<T>({
    required BuildContext context,
    required Widget contentWidget,
    String? title,
    List<MyTextAction>? actionTitles,
  }) {
    return showMyCupertinoDialog<T>(
      context: context,
      builder: (context) => MyCupertinoAlertDialog(
        title: title,
        contentWidget: contentWidget,
        actionTitles: actionTitles,
      ),
    );
  }

  static void dismiss<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}

class MyTextAction {
  MyTextAction({
    required this.title,
    required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  /// Set to true if button is the default choice in the dialog.
  ///
  /// Default buttons have bold text. Similar to
  /// [UIAlertController.preferredAction](https://developer.apple.com/documentation/uikit/uialertcontroller/1620102-preferredaction),
  /// but more than one action can have this attribute set to true in the same
  /// [CupertinoAlertDialog].
  ///
  /// This parameters defaults to false and cannot be null.
  final bool isDefaultAction;

  /// Whether this action destroys an object.
  ///
  /// For example, an action that deletes an email is destructive.
  ///
  /// Defaults to false and cannot be null.
  final bool isDestructiveAction;
  final String title;
}

/// 自定义CupertinoAlertDialog，苹果风格
class MyCupertinoAlertDialog extends CupertinoAlertDialog {
  // final String? title;
  // final String? content;
  // final List<String> actionTitles;

  MyCupertinoAlertDialog({
    super.key,
    String? title,
    String? content,
    Widget? contentWidget,
    List<MyTextAction>? actionTitles,
  }) : super(
         title: title != null ? Text(title) : null,
         content:
             contentWidget ??
             (content != null
                 ? _DialogContent(
                     content: content,
                   )
                 : null),
         actions: actionTitles != null
             ? actionTitles.map((item) {
                 return CupertinoDialogAction(
                   isDefaultAction: item.isDefaultAction,
                   isDestructiveAction: item.isDestructiveAction,
                   onPressed: item.onPressed,
                   textStyle: TextStyle(
                     color: item.isDestructiveAction ? null : AppColors.primary500,
                   ),
                   child: Text(item.title),
                 );
               }).toList()
             : [],
       );

  // MyAlertDialog({
  //   Key? key,
  //   String? title,
  //   String? content,
  //   List<String>? actionTitles,
  //   Function(int)? actionCallback,
  // }) : super(
  //           key: key,
  //           title: title != null ? Text(title) : null,
  //           content: content != null
  //               ? _DialogContent(
  //                   content: content,
  //                 )
  //               : null,
  //           actions: actionTitles != null
  //               ? actionTitles.map((item) {
  //                   final index = actionTitles.indexOf(item);
  //                   return CupertinoDialogAction(
  //                     child: Text(item),
  //                     onPressed: () {
  //                       if (actionCallback != null) {
  //                         actionCallback(index);
  //                       }
  //                     },
  //                   );
  //                 }).toList()
  //               : []);
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({
    required this.content,
  });
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Text(content),
    );
    // return Padding(
    //   padding: const EdgeInsets.only(top: 10),
    //   child: SingleChildScrollView(
    //     child: Text(content),
    //   ),
    // );
  }
}

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
