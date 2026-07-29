import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_alert_dialog.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_cupertino_alert_dialog.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_pop_loading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class DialogDemoPage extends StatelessWidget {
  const DialogDemoPage({super.key});

  static Widget _buildServiceRow(IconData icon, String title, String price) {
    return Row(
      children: [
        Icon(icon, size: 20),
        SizedBox(width: 8.w),
        Expanded(child: Text(title)),
        Text(price, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('对话框与弹窗 Dialogs')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Material Dialog
            _SectionCard(
              title: 'MyDialogHelper',
              subtitle: 'Material 风格对话框',
              children: [
                _DemoButton(
                  label: '简单确认对话框',
                  onPressed: () => unawaited(
                    MyDialogHelper.showSimpleDialog(
                      context: context,
                      title: '提示',
                      contentWidget: const Text('确定要执行此操作吗？'),
                      onConfirm: (ctx) => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
                _DemoButton(
                  label: '仅确认按钮',
                  onPressed: () => unawaited(
                    MyDialogHelper.showSimpleDialog(
                      context: context,
                      title: '操作成功',
                      contentWidget: const Text('您的订单已提交成功！'),
                      showCancelButton: false,
                      confirmText: '知道了',
                      onConfirm: (ctx) => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
                _DemoButton(
                  label: '自定义内容对话框',
                  onPressed: () => unawaited(
                    MyDialogHelper.showSimpleDialog(
                      context: context,
                      title: '选择服务',
                      contentWidget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildServiceRow(
                            Icons.cleaning_services,
                            '日常清洁',
                            '¥99/次',
                          ),
                          SizedBox(height: 8.h),
                          _buildServiceRow(
                            Icons.home_repair_service,
                            '深度清洁',
                            '¥299/次',
                          ),
                        ],
                      ),
                      onConfirm: (ctx) => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Cupertino Dialog
            _SectionCard(
              title: 'MyCupertinoDialogHelper',
              subtitle: 'iOS 风格对话框',
              children: [
                _DemoButton(
                  label: 'iOS 确认对话框',
                  onPressed: () => unawaited(
                    MyCupertinoDialogHelper.showDialog(
                      context: context,
                      content: '确定要删除这条记录吗？此操作不可撤销。',
                      actionTitles: [
                        MyTextAction(
                          title: '取消',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        MyTextAction(
                          title: '删除',
                          isDestructiveAction: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
                _DemoButton(
                  label: 'iOS 多操作对话框',
                  onPressed: () => unawaited(
                    MyCupertinoDialogHelper.showDialog(
                      context: context,
                      title: '分享到',
                      content: '选择分享方式',
                      actionTitles: [
                        MyTextAction(
                          title: '微信好友',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        MyTextAction(
                          title: '朋友圈',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        MyTextAction(
                          title: '取消',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Toast
            _SectionCard(
              title: 'MyEasyPopMessage',
              subtitle: 'Toast 提示（基于 EasyLoading）',
              children: [
                _DemoButton(
                  label: '成功提示',
                  onPressed: () => MyEasyPopMessage.showSuccessUnawaited('操作成功！'),
                ),
                _DemoButton(
                  label: '错误提示',
                  onPressed: () => MyEasyPopMessage.showErrorUnawaited('操作失败，请重试'),
                ),
                _DemoButton(
                  label: '信息提示',
                  onPressed: () => MyEasyPopMessage.showInfoUnawaited('您有3条新消息'),
                ),
                _DemoButton(
                  label: 'Toast 提示',
                  onPressed: () => MyEasyPopMessage.showToastUnawaited('这是一条 Toast'),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Loading
            _SectionCard(
              title: 'MyPopLoading',
              subtitle: '加载遮罩（基于 EasyLoading）',
              children: [
                _DemoButton(
                  label: '显示 Loading（2秒后自动关闭）',
                  onPressed: () {
                    MyPopLoading.show(status: '加载中...');
                    Future.delayed(
                      const Duration(seconds: 2),
                      MyPopLoading.dismiss,
                    );
                  },
                ),
                _DemoButton(
                  label: '全屏 Loading（2秒后自动关闭）',
                  onPressed: () {
                    MyPopLoading.showFull(status: '处理中...');
                    Future.delayed(
                      const Duration(seconds: 2),
                      MyPopLoading.dismiss,
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
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
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
