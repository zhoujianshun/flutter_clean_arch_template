import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/providers/models/auth_state.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({this.onResult, super.key});
  final void Function({bool success})? onResult;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.changeReason == AuthStateChangeReason.loginSuccess) {
        widget.onResult?.call(success: true);
        unawaited(context.router.replaceAll([const AppShellRoute()]));
      } else if (next.changeReason == AuthStateChangeReason.loginFailed &&
          next.errorMessage != null) {
        unawaited(MyEasyPopMessage.showError(next.errorMessage!));
        setState(() => _isLoading = false);
      }
    });

    return Scaffold(
      body: ContentConstraint(
        maxWidth: ResponsiveTokens.maxWidthForm,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 80.h),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 48.h),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Verification code',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                if (AppConfig.mockAuth) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleDemoLogin,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Demo Login'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty) {
      unawaited(MyEasyPopMessage.showInfo('Please fill in all fields'));
      return;
    }
    setState(() => _isLoading = true);
    await ref
        .read(authProvider.notifier)
        .phoneLogin(
          phonenumber: _phoneController.text,
          smsCode: _codeController.text,
        );
  }

  Future<void> _handleDemoLogin() async {
    setState(() => _isLoading = true);
    await ref
        .read(authProvider.notifier)
        .phoneLogin(
          phonenumber: '13800138000',
          smsCode: '888888',
        );
  }
}
