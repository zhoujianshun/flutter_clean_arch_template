import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/widgets/my_bottom_navigation_bar_Item/my_red_point.dart';

///
class MyBottomNavigationBarItem extends BottomNavigationBarItem {
  MyBottomNavigationBarItem(String title, String iconName, {bool showRedPoint = false, String? redPointText})
    : super(
        label: title,
        icon: BarItemWithRedPoint(
          'assets/images/tabs/$iconName.png',
          showRedPoint: showRedPoint,
          redPointText: redPointText,
        ),
        activeIcon: BarItemWithRedPoint(
          'assets/images/tabs/${iconName}_selected.png',
          showRedPoint: showRedPoint,
          redPointText: redPointText,
        ),
      );
}

class BarItemWithRedPoint extends StatelessWidget {
  const BarItemWithRedPoint(this.iconName, {super.key, this.showRedPoint = true, this.redPointText});
  final String iconName;
  final bool showRedPoint;
  final String? redPointText;

  @override
  Widget build(BuildContext context) {
    final count = redPointText?.length ?? 0;

    final items = <Widget>[
      Image.asset(
        iconName,
        width: 24,
        gaplessPlayback: true,
      ),
    ];

    if (showRedPoint) {
      items.add(
        Positioned(
          right: count <= 2 ? -4 : (-4 * count.toDouble()),
          top: -2,
          child: MyRedPoint(
            radius: 10,
            text: redPointText,
            backgroundColor: AppAdaptiveColors.error500(context),
            textColor: AppAdaptiveColors.neutral100(context),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: items,
    );
  }
}
