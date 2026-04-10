import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/send_verification_code/send_verification_code_request.dart';
import 'package:flutter_clean_arch_template/shared/utils/validators.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/primary_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';

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
/// 功能特性：
/// - 点击获取验证码
/// - 接口调用成功后开始60秒倒计时
/// - 倒计时期间按钮不可点击
/// - 支持自定义样式和回调
class VerificationCodeButton extends ConsumerStatefulWidget {
  const VerificationCodeButton({
    required this.phone,
    super.key,
    this.type,
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

  /// 验证码类型（可选）
  final String? type;

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
  late final UserRemoteDataSource _userRemoteDataSource;

  @override
  void initState() {
    super.initState();
    _userRemoteDataSource = getIt<UserRemoteDataSource>();
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
        // setState(() {
        //   _countdown = 0;
        // });
      }
    });
  }

  /// 外部发送验证码（通过控制器调用）
  Future<bool> _sendVerificationCodeExternal({
    required String phone,
    String? type,
    VoidCallback? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!_canTap) {
      return false;
    }
    if (ValidatorsCheck.hasError(ValidatorsCheck.checkPhoneNumber(phone, context: context))) {
      return false;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _userRemoteDataSource.sendVerificationCode(
        SendVerificationCodeRequest(
          phonenumber: phone,
        ),
      );

      var success = false;
      result.fold(
        (failure) {
          // 发送失败
          final errorMessage = failure.message;
          if (mounted) {
            onError?.call(errorMessage);
            MyEasyPopMessage.showError(errorMessage);
          }
        },
        (successResult) {
          // 发送成功
          success = true;
          if (mounted) {
            onSuccess?.call();
            _startCountdown();
            final msg = '验证码已发送至 $phone';
            MyEasyPopMessage.showSuccess(msg);
          }
        },
      );

      return success;
    } catch (e) {
      if (mounted) {
        const errorMessage = '网络异常，请稍后重试';
        onError?.call(errorMessage);
        unawaited(MyEasyPopMessage.showError(errorMessage));
      }
      return false;
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

  /// 发送验证码（按钮点击时调用）
  Future<void> sendVerificationCode() async {
    await _sendVerificationCodeExternal(
      phone: widget.phone,
      type: widget.type,
      onSuccess: widget.onSuccess,
      onError: widget.onError,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;
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

    // return SizedBox(
    //   width: widget.width ?? 120.w,
    //   height: widget.height ?? 44.h,
    //   child: ElevatedButton(
    //     onPressed: _canTap ? _sendVerificationCode : null,
    //     style: ElevatedButton.styleFrom(
    //       backgroundColor: _canTap
    //           ? (widget.backgroundColor ?? colorScheme.primary)
    //           : (widget.disabledBackgroundColor ?? colorScheme.outline),
    //       foregroundColor: _canTap
    //           ? (widget.textColor ?? colorScheme.onPrimary)
    //           : (widget.disabledTextColor ?? colorScheme.onSurface.withOpacity(0.38)),
    //       shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.r),
    //       ),
    //       elevation: _canTap ? 2 : 0,
    //       shadowColor: colorScheme.shadow.withOpacity(0.1),
    //     ),
    //     child: _isLoading
    //         ? SizedBox(
    //             width: 16.w,
    //             height: 16.w,
    //             child: CircularProgressIndicator(
    //               strokeWidth: 2,
    //               valueColor: AlwaysStoppedAnimation<Color>(
    //                 widget.textColor ?? colorScheme.onPrimary,
    //               ),
    //             ),
    //           )
    //         : Text(
    //             _buttonText,
    //             style: widget.textStyle ??
    //                 TextStyle(
    //                   fontSize: 14.sp,
    //                   fontWeight: FontWeight.w500,
    //                 ),
    //           ),
    //   ),
    // );
  }
}

/// 验证码按钮的简化版本，使用默认样式
class SimpleVerificationCodeButton extends StatelessWidget {
  const SimpleVerificationCodeButton({
    required this.phone,
    super.key,
    this.type,
    this.onSuccess,
    this.onError,
  });

  final String phone;
  final String? type;
  final VoidCallback? onSuccess;
  final void Function(String error)? onError;

  @override
  Widget build(BuildContext context) {
    return VerificationCodeButton(
      phone: phone,
      type: type,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
