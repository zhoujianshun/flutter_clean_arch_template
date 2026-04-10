import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_button.dart';

/// 底部选择器助手类
/// 提供统一的底部选择器显示接口
/// 适用于需要从多个选项中选择一个的场景
class BottomPickerHelper {
  static Future<T?> show<T>(
    BuildContext context, {
    required List<BottomPickerItemModel<T>> items,
    required void Function(BottomPickerItemModel<T> selectedItem) onConfirm,
    T? initialValue,
  }) {
    return showMyModalPop<T>(
      context: context,
      child: BottomPicker<T>(
        items: items,
        initialValue: initialValue,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<T?> showMyModalPop<T>({required BuildContext context, required Widget child}) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            // padding: const EdgeInsets.only(top: 6.0),
            // The Bottom margin is provided to align the popup above the system navigation bar.
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            // Provide a background color for the popup.
            color: CupertinoColors.systemBackground.resolveFrom(context),
            // Use a SafeArea widget to avoid system overlaps.
            child: SafeArea(
              top: false,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

final double _kItemExtent = 36.0.sp;

class BottomPicker<T> extends StatelessWidget {
  const BottomPicker({
    required this.items,
    required this.onConfirm,
    super.key,
    this.initialValue,
  });
  final List<BottomPickerItemModel<T>> items;
  final T? initialValue;
  final void Function(BottomPickerItemModel<T> selectedItem) onConfirm;

  @override
  Widget build(BuildContext context) {
    var index = 0;
    if (initialValue != null) {
      index = items.indexWhere((element) => element.value == initialValue);
    }
    final scrollController = FixedExtentScrollController(
      initialItem: index,
    );
    return SizedBox(
      height: 216.sp,
      child: Column(
        children: [
          Container(
            // color: Colors.red,
            padding: EdgeInsets.symmetric(vertical: 4.sp, horizontal: 6.sp).copyWith(bottom: 0.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyButton.text(
                  text: '取消',
                  fontSize: 15.sp,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                MyButton.text(
                  text: '确定',
                  fontSize: 15.sp,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    final item = items[scrollController.selectedItem];
                    // debugPrint(item.label);
                    onConfirm(item);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              // magnification: 1.22,
              // squeeze: 1.2,
              useMagnifier: true,
              itemExtent: _kItemExtent,
              // This sets the initial item.
              scrollController: scrollController,
              // This is called when selected item is changed.
              onSelectedItemChanged: (int selectedItem) {
                // setState(() {
                //   _selectedFruit = selectedItem;
                // });
              },
              children: List<Widget>.generate(items.length, (int index) {
                return Center(child: Text(items[index].label));
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomPickerItemModel<T> {
  BottomPickerItemModel({required this.label, required this.value});
  final String label;
  final T value;
}
