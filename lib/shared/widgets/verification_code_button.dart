import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/shared/utils/validators.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/primary_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 验证码按钮控制器
/// 用于外部控制验证码按钮的状态和发送验证码
class VerificationCodeController {
  _VerificationCodeButtonState? _state;

  /// 绑定到按钮状态
  void _bindState(_VerificationCodeButtonState state) {
    _state = state;
  }

  /// 解绑状态
  void _unbindState() {
    _state = null;
  }

  /// 外部触发开始倒计时
  /// 当验证码通过其他方式发送成功时调用
  void startCountdown() {
    _state?._startCountdown();
  }

  /// 直接发送验证码
  /// 这是推荐的发送方式，会自动处理状态同步
  Future<void> sendVerificationCode() async {
    return _state!.sendVerificationCode();
  }

  /// 获取当前倒计时状态
  bool get isCountingDown => _state?._countdown != null && _state!._countdown > 0;

  /// 获取当前倒计时剩余时间
  int get countdown => _state?._countdown ?? 0;

  /// 获取是否可以发送验证码
  bool get canSend => _state?._canTap ?? false;

  /// 获取是否正在发送
  bool get isLoading => _state?._isLoading ?? false;
}

/// 获取验证码按钮组件
///
/// 纯 UI 组件：只负责倒计时与 loading 状态管理，发送动作由 [onSend]
/// 回调注入（依赖倒置，shared 层不依赖任何 feature）。
///
/// 功能特性：
/// - 点击调用 [onSend] 发送验证码
/// - 回调返回 true 后开始倒计时（默认 60 秒）
/// - 倒计时期间按钮不可点击
class VerificationCodeButton extends ConsumerStatefulWidget {
  const VerificationCodeButton({
    required this.phone,
    required this.onSend,
    super.key,
    this.onSuccess,
    this.onError,
    this.width,
    this.height,
    this.countdownDuration = 60,
    this.controller,
    this.minimumSize,
  });

  /// 手机号码
  final String phone;

  /// 发送验证码的回调（由调用方注入，如走 AuthProvider）
  ///
  /// 返回 true 表示发送成功（组件开始倒计时），false 表示失败。
  final Future<bool> Function(String phone) onSend;

  /// 成功回调
  final VoidCallback? onSuccess;

  /// 错误回调
  final void Function(String error)? onError;

  /// 按钮宽度
  final double? width;

  /// 按钮高度
  final double? height;

  /// 倒计时时长（秒）
  final int countdownDuration;

  /// 外部控制器（可选）
  final VerificationCodeController? controller;
  final Size? minimumSize;

  @override
  ConsumerState<VerificationCodeButton> createState() => _VerificationCodeButtonState();
}

class _VerificationCodeButtonState extends ConsumerState<VerificationCodeButton> {
  Timer? _timer;
  int _countdown = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 绑定控制器
    widget.controller?._bindState(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 解绑控制器
    widget.controller?._unbindState();
    super.dispose();
  }

  /// 是否可以点击
  bool get _canTap => _countdown == 0 && !_isLoading;

  /// 按钮文本
  String get _buttonText {
    if (_isLoading) {
      return '发送中...';
    } else if (_countdown > 0) {
      return '${_countdown}s后重试';
    } else {
      return '获取验证码';
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() {
      _countdown = widget.countdownDuration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
      }
    });
  }

  /// 发送验证码（按钮点击时调用）
  Future<void> sendVerificationCode() async {
    if (!_canTap) {
      return;
    }
    if (ValidatorsCheck.hasError(ValidatorsCheck.checkPhoneNumber(widget.phone, context: context))) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.onSend(widget.phone);

      if (!mounted) return;
      if (success) {
        widget.onSuccess?.call();
        _startCountdown();
        MyEasyPopMessage.showSuccess('验证码已发送至 ${widget.phone}');
      } else {
        const errorMessage = '验证码发送失败，请稍后重试';
        widget.onError?.call(errorMessage);
        unawaited(MyEasyPopMessage.showError(errorMessage));
      }
    } catch (e) {
      if (mounted) {
        const errorMessage = '网络异常，请稍后重试';
        widget.onError?.call(errorMessage);
        unawaited(MyEasyPopMessage.showError(errorMessage));
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _isLoading = false;
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final btnColor = AppAdaptiveColors.primary(context);
    return PrimaryButton(
      isRounded: true,
      isLoading: _isLoading,
      width: widget.width,
      height: widget.height,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w),
      disabledForegroundColor: btnColor.withValues(alpha: 0.7),
      disabledBackgroundColor: btnColor.withValues(alpha: 0.1),
      foregroundColor: btnColor,
      backgroundColor: btnColor.withValues(alpha: 0.16),
      onPressed: _canTap ? sendVerificationCode : null,
      minimumSize: widget.minimumSize,
      child: Text(
        _buttonText,
        style: AppTextStyles.bodyXSmall.copyWith(),
      ),
    );
  }
}

/// 验证码按钮的简化版本，使用默认样式
class SimpleVerificationCodeButton extends StatelessWidget {
  const SimpleVerificationCodeButton({
    required this.phone,
    required this.onSend,
    super.key,
    this.onSuccess,
    this.onError,
  });

  final String phone;
  final Future<bool> Function(String phone) onSend;
  final VoidCallback? onSuccess;
  final void Function(String error)? onError;

  @override
  Widget build(BuildContext context) {
    return VerificationCodeButton(
      phone: phone,
      onSend: onSend,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
