import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/primary_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/form/form_title.dart';
import 'package:flutter_clean_arch_template/shared/widgets/round_check_box.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class FormInputDemoPage extends StatefulWidget {
  const FormInputDemoPage({super.key});

  @override
  State<FormInputDemoPage> createState() => _FormInputDemoPageState();
}

class _FormInputDemoPageState extends State<FormInputDemoPage> {
  bool _checkA = false;
  bool _checkB = true;
  bool _checkC = false;

  // 模拟验证码按钮状态
  int _countdown = 0;
  bool _isSending = false;

  void _simulateSendCode() {
    setState(() => _isSending = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _countdown = 10;
      });
      _startCountdown();
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _countdown <= 0) return;
      setState(() => _countdown--);
      if (_countdown > 0) _startCountdown();
    });
  }

  String get _codeButtonText {
    if (_isSending) return '发送中...';
    if (_countdown > 0) return '${_countdown}s后重试';
    return '获取验证码';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('表单与输入 Form & Input')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // FormTitle
            _SectionTitle('FormTitle', '表单标签（支持必填标记）'),
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    const FormTitle(title: '用户名', isRequired: true),
                    TextField(
                      decoration: InputDecoration(
                        hintText: '请输入用户名',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    const FormTitle(title: '备注'),
                    TextField(
                      decoration: InputDecoration(
                        hintText: '选填',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // RoundCheckBox
            _SectionTitle('RoundCheckBox', '圆角复选框（带动画）'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        RoundCheckBox(
                          isChecked: _checkA,
                          size: 24.w,
                          onTap: ({isChecked}) =>
                              setState(() => _checkA = isChecked ?? false),
                        ),
                        SizedBox(width: 12.w),
                        const Text('圆角复选框（默认）'),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        RoundCheckBox(
                          isChecked: _checkB,
                          size: 24.w,
                          checkedColor: Colors.blue,
                          onTap: ({isChecked}) =>
                              setState(() => _checkB = isChecked ?? false),
                        ),
                        SizedBox(width: 12.w),
                        const Text('自定义颜色（蓝色）'),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        RoundCheckBox(
                          isChecked: _checkC,
                          isRound: false,
                          size: 24.w,
                          onTap: ({isChecked}) =>
                              setState(() => _checkC = isChecked ?? false),
                        ),
                        SizedBox(width: 12.w),
                        const Text('方角复选框（isRound: false）'),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        RoundCheckBox(
                          isChecked: true,
                          size: 24.w,
                          onTap: null,
                        ),
                        SizedBox(width: 12.w),
                        const Text('Disabled 状态'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // VerificationCodeButton 模拟
            _SectionTitle(
              'VerificationCodeButton',
              '验证码按钮（此处为状态模拟演示）',
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '实际组件依赖 UserRemoteDataSource，这里模拟三种状态：',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '请输入手机号',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        PrimaryButton(
                          isRounded: true,
                          isLoading: _isSending,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.16),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          onPressed:
                              (_countdown == 0 && !_isSending)
                                  ? _simulateSendCode
                                  : null,
                          child: Text(
                            _codeButtonText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
