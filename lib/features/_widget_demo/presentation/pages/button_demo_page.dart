import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_filled_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/my_outlined_button.dart';
import 'package:flutter_clean_arch_template/shared/widgets/button/primary_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class ButtonDemoPage extends StatefulWidget {
  const ButtonDemoPage({super.key});

  @override
  State<ButtonDemoPage> createState() => _ButtonDemoPageState();
}

class _ButtonDemoPageState extends State<ButtonDemoPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('按钮 Buttons')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Loading 状态开关
            Card(
              child: SwitchListTile(
                title: const Text('Loading 状态'),
                subtitle: const Text('全局切换所有按钮的 loading 效果'),
                value: _isLoading,
                onChanged: (v) => setState(() => _isLoading = v),
              ),
            ),
            SizedBox(height: 16.h),

            // MyButton
            _SectionTitle('MyButton', '无背景色，类 iOS 按钮'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [
                    MyButton(
                      isLoading: _isLoading,
                      onPressed: () {},
                      child: const Text('默认按钮'),
                    ),
                    MyButton.round(
                      onPressed: () {},
                      child: const Text('圆角按钮'),
                    ),
                    MyButton.text(
                      text: '文本按钮',
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                    MyButton(
                      onPressed: null,
                      child: const Text('Disabled'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // MyFilledButton
            _SectionTitle('MyFilledButton', '主题色填充，类 iOS 按钮'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [
                    MyFilledButton(
                      isLoading: _isLoading,
                      onPressed: () {},
                      child: const Text('默认填充'),
                    ),
                    MyFilledButton.round(
                      isLoading: _isLoading,
                      onPressed: () {},
                      child: const Text('圆角填充'),
                    ),
                    MyFilledButton.roundText(
                      text: '圆角文本',
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                    MyFilledButton.text(
                      text: '文本填充',
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                    MyFilledButton(
                      onPressed: null,
                      child: const Text('Disabled'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // MyOutlinedButton
            _SectionTitle('MyOutlinedButton', '边框按钮，支持 primary / plain'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [
                    MyOutlinedButton.text(
                      text: 'Primary',
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                    MyOutlinedButton.text(
                      text: 'Plain',
                      type: MyOutlinedButtonType.plain,
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                    MyOutlinedButton.roundText(
                      text: '圆角 Primary',
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                    MyOutlinedButton.roundText(
                      text: '圆角 Plain',
                      type: MyOutlinedButtonType.plain,
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                    MyOutlinedButton(
                      onPressed: null,
                      child: const Text('Disabled'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // PrimaryButton
            _SectionTitle('PrimaryButton', 'Material ElevatedButton 风格'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      isLoading: _isLoading,
                      onPressed: () {},
                      child: const Text('默认按钮'),
                    ),
                    SizedBox(height: 12.h),
                    PrimaryButton.round(
                      isLoading: _isLoading,
                      onPressed: () {},
                      child: const Text('圆角按钮'),
                    ),
                    SizedBox(height: 12.h),
                    PrimaryButton.roundText(
                      text: '圆角文本按钮',
                      onPressed: () {},
                    ),
                    SizedBox(height: 12.h),
                    PrimaryButton.text(
                      text: '文本按钮',
                      onPressed: () {},
                    ),
                    SizedBox(height: 12.h),
                    PrimaryButton(
                      onPressed: null,
                      child: const Text('Disabled'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 高度差异分析
            _SectionTitle('高度差异分析', '各按钮 minimumSize 默认值不同'),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '同一行中各按钮高度不一致的原因：',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: 8.h),
                    const Text(
                      '• MyButton → CupertinoButton 默认 min 44px\n'
                      '• PrimaryButton → ElevatedButton 默认 min 36px\n'
                      '• MyFilledButton → 已设 Size.zero，无最小高度\n'
                      '• MyOutlinedButton → CupertinoButton min 0 + 边框',
                    ),
                    SizedBox(height: 8.h),
                    const Text(
                      '解决：传入 minimumSize: Size.zero 统一取消最小尺寸\n'
                      '再用 padding 精确控制内边距',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 超小 padding 按钮
            _SectionTitle(
              '紧凑按钮（超小 padding）',
              '通过 minimumSize: Size.zero + padding 实现',
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MyFilledButton(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      onPressed: () {},
                      child: const Text('极小填充'),
                    ),
                    MyOutlinedButton.text(
                      text: '极小边框',
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      onPressed: () {},
                    ),
                    MyButton(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      onPressed: () {},
                      child: const Text('极小文本'),
                    ),
                    PrimaryButton(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      onPressed: () {},
                      child: const Text('极小主按钮'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // 全宽按钮示例
            _SectionTitle('全宽按钮', '常见的表单提交场景'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MyFilledButton.roundText(
                      text: '提交订单',
                      isLoading: _isLoading,
                      width: double.infinity,
                      height: 48.h,
                      onPressed: () {},
                    ),
                    SizedBox(height: 12.h),
                    MyOutlinedButton.roundText(
                      text: '取消订单',
                      type: MyOutlinedButtonType.plain,
                      width: double.infinity,
                      height: 48.h,
                      expand: true,
                      onPressed: () {},
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
