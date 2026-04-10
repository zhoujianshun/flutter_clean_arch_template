import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

/// 接单倒计时头部组件
class Countdown extends StatefulWidget {
  const Countdown({
    required this.remainingTime,
    this.backgroundColor,
    this.title,
    this.titleStyle,
    this.onCountdownExpired,
    super.key,
  });

  // final DateTime expireTime;
  final Duration remainingTime;
  final Color? backgroundColor;
  final String? title;
  final TextStyle? titleStyle;
  final VoidCallback? onCountdownExpired;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  /// 接单倒计时时长（默认5分钟）
  // static const Duration _countdownDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 初始化倒计时
  void _initializeCountdown() {
    // 假设订单创建时间为 startTime，实际项目中应该使用订单的创建时间
    // final elapsed = DateTime.now().difference(widget.expireTime);
    // AppLogger.i('elapsed: $elapsed');
    // _remainingTime = elapsed;

    _remainingTime = widget.remainingTime;
    // 如果时间已过，设置为0
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    if (_remainingTime.inSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          } else {
            _timer?.cancel();
            _onCountdownExpired();
          }
        });
      }
    });
  }

  /// 倒计时结束处理
  void _onCountdownExpired() {
    widget.onCountdownExpired?.call();
  }

  /// 格式化倒计时显示
  String _formatCountdown(Duration duration) {
    if (duration.inSeconds <= 0) {
      return '00:00';
    }
    final days = duration.inHours ~/ 24;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    var result =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    if (days > 0) {
      result = '${days.toString().padLeft(2, '0')}天 $result';
    }
    return result;
  }

  /// 获取倒计时颜色
  Color _getCountdownColor() {
    return AppAdaptiveColors.error500(context);
    // if (_remainingTime.inSeconds <= 0) {
    //   return Colors.red;
    // } else if (_remainingTime.inSeconds <= 60) {
    //   return Colors.orange;
    // } else {
    //   return AppAdaptiveColors.error500(context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      height: 40.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: widget.titleStyle ??
                  AppTextStyles.bodyMedium.copyWith(
                    color: AppAdaptiveColors.neutral900(context),
                  ),
            ),
            SizedBox(width: 8.w),
          ],
          Text(
            _formatCountdown(_remainingTime),
            style: AppTextStyles.bodyMedium.copyWith(
              color: _getCountdownColor(),
              fontWeight: FontWeight.w500,
              fontFamily: AppTextStyles.fontFamilyMedium,
              // fontFeatures: const [FontFeature.tabularFigures()],
              // height: 1.2,
            ),
          )
        ],
      ),
    );
  }
}
