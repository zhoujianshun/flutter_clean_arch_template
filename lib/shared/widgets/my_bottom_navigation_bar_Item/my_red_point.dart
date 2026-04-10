import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyRedPoint extends StatelessWidget {
  const MyRedPoint({super.key, this.radius, this.margin, this.text, this.backgroundColor, this.textColor});
  final double? radius;
  final EdgeInsetsGeometry? margin;
  final String? text;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final size = radius ?? 10.0.w;
    return Container(
      margin: margin ?? EdgeInsets.zero,
      // width: radius ?? 10.0.w,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      height: size,
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xccfa523a),
        borderRadius: BorderRadius.circular(size / 2),
        // shape: BoxShape.circle,
      ),
      alignment: Alignment.center,

      child: text != null
          ? Center(
              child: Text(
                text!,
                style: TextStyle(color: textColor ?? Colors.white, fontSize: 10),
              ),
            )
          : null,
    );
  }
}
