import 'package:flutter/material.dart';

/// 刘海屏检测工具类
class DeviceUtils {
  DeviceUtils._();

  /// 判断是否是刘海屏/异形屏
  static bool hasNotch(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return _hasNotch(mediaQuery);
  }

  /// 获取刘海屏详细信息
  static NotchInfo getNotchInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return _getNotchInfo(context, mediaQuery);
  }

  /// 内部方法：判断是否是刘海屏
  static bool _hasNotch(MediaQueryData mediaQuery) {
    // 方法1：检查顶部安全区域
    final topPadding = mediaQuery.padding.top;

    // iPhone X及以上：状态栏高度通常为44，普通iPhone为20
    // Android异形屏：状态栏高度通常大于24
    if (topPadding > 24) {
      return true;
    }

    // 方法2：检查底部安全区域（iPhone X系列有底部安全区域）
    if (mediaQuery.padding.bottom > 0) {
      return true;
    }

    // 方法3：检查屏幕比例（异形屏通常比例较高）
    final screenRatio = mediaQuery.size.height / mediaQuery.size.width;
    if (screenRatio > 2.0) {
      return true;
    }

    return false;
  }

  /// 内部方法：获取刘海屏信息
  static NotchInfo _getNotchInfo(BuildContext context, MediaQueryData mediaQuery) {
    final padding = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;
    final size = mediaQuery.size;

    return NotchInfo(
      hasNotch: _hasNotch(mediaQuery),
      topSafeArea: padding.top,
      bottomSafeArea: padding.bottom,
      leftSafeArea: padding.left,
      rightSafeArea: padding.right,
      statusBarHeight: viewPadding.top,
      screenRatio: size.height / size.width,
      deviceType: _getDeviceType(context, mediaQuery),
    );
  }

  /// 内部方法：获取设备类型
  static String _getDeviceType(BuildContext context, MediaQueryData mediaQuery) {
    final size = mediaQuery.size;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    // iPhone判断
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      if (topPadding >= 44 && bottomPadding >= 20) {
        if (size.height >= 900) return 'iPhone Pro Max';
        if (size.height >= 850) return 'iPhone Pro';
        if (size.height >= 800) return 'iPhone Plus';
        return 'iPhone X系列';
      } else if (topPadding >= 20) {
        return 'iPhone经典款';
      }
    }

    // Android判断
    if (Theme.of(context).platform == TargetPlatform.android) {
      if (topPadding > 24) {
        return 'Android异形屏';
      } else {
        return 'Android普通屏';
      }
    }

    return '未知设备';
  }

  /// 判断是否存在底部安全区域
  static bool hasBottomSafeArea(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.bottom > 0;
  }

  static bool isIphone(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }

  static bool isAndroid(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.android;
  }

  /// 获取底部安全区域空间,如果存在底部安全区域,则返回0,否则返回value
  static double safeBottomSpaceWithValue(BuildContext context, double value) {
    return hasBottomSafeArea(context) ? 0 : value;
  }
}

/// 刘海屏信息数据类
class NotchInfo {
  const NotchInfo({
    required this.hasNotch,
    required this.topSafeArea,
    required this.bottomSafeArea,
    required this.leftSafeArea,
    required this.rightSafeArea,
    required this.statusBarHeight,
    required this.screenRatio,
    required this.deviceType,
  });

  final bool hasNotch;
  final double topSafeArea;
  final double bottomSafeArea;
  final double leftSafeArea;
  final double rightSafeArea;
  final double statusBarHeight;
  final double screenRatio;
  final String deviceType;

  @override
  String toString() {
    return 'NotchInfo('
        'hasNotch: $hasNotch, '
        'topSafeArea: $topSafeArea, '
        'bottomSafeArea: $bottomSafeArea, '
        'statusBarHeight: $statusBarHeight, '
        'screenRatio: ${screenRatio.toStringAsFixed(2)}, '
        'deviceType: $deviceType'
        ')';
  }
}
