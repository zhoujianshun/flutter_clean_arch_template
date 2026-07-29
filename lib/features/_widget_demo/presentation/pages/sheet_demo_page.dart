import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/bottom_picker/bottom_picker.dart';
import 'package:flutter_clean_arch_template/shared/widgets/modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_clean_arch_template/shared/widgets/modal_bottom_sheet_selector/bottom_sheet_selector.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class SheetDemoPage extends StatelessWidget {
  const SheetDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('底部面板与选择器 Sheets')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _SectionCard(
              title: 'MyModalBottomSheetHelper',
              subtitle: '基础底部面板',
              children: [
                _DemoButton(
                  label: '基础 BottomSheet',
                  onPressed: () => unawaited(
                    MyModalBottomSheetHelper.showMyModalBottomSheet(
                      context: context,
                      isDismissible: true,
                      enableDrag: true,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('这是一个基础的 BottomSheet'),
                            SizedBox(height: 16.h),
                            const Text('支持自定义任意内容'),
                            SizedBox(height: 24.h),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('关闭'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _DemoButton(
                  label: '带标题的 BottomSheet',
                  onPressed: () => unawaited(
                    MyModalBottomSheetHelper.showModalBottomSheetWithHeader(
                      context: context,
                      title: '选择地址',
                      isDismissible: true,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.home),
                              title: const Text('家'),
                              subtitle: const Text('北京市朝阳区xxx街道'),
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                            ListTile(
                              leading: const Icon(Icons.work),
                              title: const Text('公司'),
                              subtitle: const Text('北京市海淀区xxx大厦'),
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            _SectionCard(
              title: 'MyModalBottomSheetSelectorHelper',
              subtitle: 'ActionSheet 风格选择器',
              children: [
                _DemoButton(
                  label: '操作选择器',
                  onPressed: () => unawaited(
                    MyModalBottomSheetSelectorHelper.show(
                      context,
                      title: '选择操作',
                      isDismissible: true,
                      actions: [
                        BottomSelectorItem(
                          title: '拍照',
                          onPressed: (ctx) {
                            Navigator.of(ctx).pop();
                            MyEasyPopMessage.showSuccessUnawaited('已选择：拍照');
                          },
                        ),
                        BottomSelectorItem(
                          title: '从相册选择',
                          onPressed: (ctx) {
                            Navigator.of(ctx).pop();
                            MyEasyPopMessage.showSuccessUnawaited('已选择：相册');
                          },
                        ),
                        BottomSelectorItem(
                          title: '删除照片',
                          isDestructive: true,
                          onPressed: (ctx) {
                            Navigator.of(ctx).pop();
                            MyEasyPopMessage.showErrorUnawaited('已删除');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            _SectionCard(
              title: 'BottomPickerHelper',
              subtitle: 'Cupertino 滚轮选择器',
              children: [
                _DemoButton(
                  label: '城市选择器',
                  onPressed: () => unawaited(
                    BottomPickerHelper.show<String>(
                      context,
                      items: [
                        BottomPickerItemModel(label: '北京', value: 'beijing'),
                        BottomPickerItemModel(
                            label: '上海', value: 'shanghai'),
                        BottomPickerItemModel(
                            label: '广州', value: 'guangzhou'),
                        BottomPickerItemModel(label: '深圳', value: 'shenzhen'),
                        BottomPickerItemModel(label: '杭州', value: 'hangzhou'),
                        BottomPickerItemModel(label: '成都', value: 'chengdu'),
                      ],
                      initialValue: 'shanghai',
                      onConfirm: (item) {
                        MyEasyPopMessage.showSuccessUnawaited(
                            '已选择：${item.label}');
                      },
                    ),
                  ),
                ),
                _DemoButton(
                  label: '年份选择器',
                  onPressed: () => unawaited(
                    BottomPickerHelper.show<int>(
                      context,
                      items: List.generate(
                        10,
                        (i) => BottomPickerItemModel(
                          label: '${2020 + i} 年',
                          value: 2020 + i,
                        ),
                      ),
                      initialValue: 2026,
                      onConfirm: (item) {
                        MyEasyPopMessage.showSuccessUnawaited(
                            '已选择：${item.label}');
                      },
                    ),
                  ),
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
            Wrap(spacing: 8.w, runSpacing: 8.h, children: children),
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
    return FilledButton.tonal(onPressed: onPressed, child: Text(label));
  }
}
