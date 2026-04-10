import 'dart:async';

import 'package:flutter/material.dart';

/// 实时时钟控制器
///
/// 提供获取当前时间的功能，包括日期和时间
class RealTimeClockController extends ChangeNotifier {
  DateTime _currentDateTime = DateTime.now();

  /// 获取当前日期时间
  DateTime get currentDateTime => _currentDateTime;

  /// 获取格式化的时间字符串 (HH:mm:ss)
  String get formattedTime {
    return '${_formatNumber(_currentDateTime.hour)}:'
        '${_formatNumber(_currentDateTime.minute)}:'
        '${_formatNumber(_currentDateTime.second)}';
  }

  /// 获取格式化的日期字符串 (yyyy-MM-dd)
  String get formattedDate {
    return '${_currentDateTime.year}-'
        '${_formatNumber(_currentDateTime.month)}-'
        '${_formatNumber(_currentDateTime.day)}';
  }

  /// 获取格式化的日期时间字符串 (yyyy-MM-dd HH:mm:ss)
  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  /// 更新当前时间
  void _updateDateTime(DateTime dateTime) {
    _currentDateTime = dateTime;
    notifyListeners();
  }

  /// 格式化数字，确保两位数显示
  String _formatNumber(int number) {
    return number.toString().padLeft(2, '0');
  }
}

/// 实时时钟组件
///
/// 显示当前时间，格式为 HH:mm:ss
/// 每秒自动更新一次
class RealTimeClock extends StatefulWidget {
  const RealTimeClock({
    super.key,
    this.style,
    this.textAlign,
    this.controller,
    this.onTimeChanged,
  });

  /// 文本样式
  final TextStyle? style;

  /// 文本对齐方式
  final TextAlign? textAlign;

  /// 时钟控制器
  final RealTimeClockController? controller;
  final void Function(DateTime)? onTimeChanged;

  @override
  State<RealTimeClock> createState() => _RealTimeClockState();
}

class _RealTimeClockState extends State<RealTimeClock> {
  late Timer _timer;
  // late String _currentTime = '';
  RealTimeClockController? _internalController;

  /// 获取控制器（外部传入的或内部创建的）
  RealTimeClockController get _controller {
    return widget.controller ?? _internalController!;
  }

  @override
  void initState() {
    super.initState();
    // 如果没有外部控制器，创建内部控制器
    if (widget.controller == null) {
      _internalController = RealTimeClockController();
    }

    _controller.addListener(_onControllerChanged);
    _updateTime();
    _startTimer();
  }

  void _onControllerChanged() {
    // 只有当使用外部控制器时才需要监听变化并更新UI
    if (widget.controller != null && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _timer.cancel();
    // 只有内部创建的控制器才需要释放
    _internalController?.dispose();
    super.dispose();
  }

  /// 启动定时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  /// 更新当前时间
  void _updateTime() {
    final now = DateTime.now();

    // 更新控制器中的时间
    _controller._updateDateTime(now);

    // 调用时间变化回调
    if (widget.onTimeChanged != null) {
      // 使用 Future.microtask 避免在 build 期间调用回调
      Future.microtask(() {
        widget.onTimeChanged?.call(now);
      });
    }

    // 如果使用内部控制器，需要手动触发UI更新
    if (widget.controller == null && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _controller.formattedTime,
      style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      textAlign: widget.textAlign,
    );
  }
}
