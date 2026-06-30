import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/utils/responsive_utils.dart';
import 'package:flutter_clean_arch_template/shared/widgets/content_constraint.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式表单示例
///
/// 演示表单在不同屏幕尺寸下的布局差异：
/// - **手机**：全宽单列表单，字段纵向排列
/// - **平板**：居中卡片容器，关联字段双列排列（如姓/名、省/市）
@RoutePage()
class ResponsiveFormPage extends StatelessWidget {
  const ResponsiveFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('响应式表单示例')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (ResponsiveUtils.isCompact(constraints)) {
            return _CompactForm();
          }
          return _MediumForm();
        },
      ),
    );
  }
}

/// 手机布局：全宽单列表单
class _CompactForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('个人信息', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 24.h),
          const TextField(decoration: InputDecoration(labelText: '姓', prefixIcon: Icon(Icons.person_outline))),
          SizedBox(height: 16.h),
          const TextField(decoration: InputDecoration(labelText: '名')),
          SizedBox(height: 16.h),
          const TextField(
            decoration: InputDecoration(labelText: '邮箱', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16.h),
          const TextField(
            decoration: InputDecoration(labelText: '手机号', prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24.h),
          Text('地址信息', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16.h),
          const TextField(decoration: InputDecoration(labelText: '省/直辖市', prefixIcon: Icon(Icons.location_on_outlined))),
          SizedBox(height: 16.h),
          const TextField(decoration: InputDecoration(labelText: '市/区')),
          SizedBox(height: 16.h),
          const TextField(decoration: InputDecoration(labelText: '详细地址'), maxLines: 3),
          SizedBox(height: 16.h),
          const TextField(decoration: InputDecoration(labelText: '邮政编码')),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: FilledButton(onPressed: () {}, child: const Text('提交')),
          ),
        ],
      ),
    );
  }
}

/// 平板布局：居中卡片 + 双列字段
class _MediumForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ContentConstraint(
        maxWidth: ResponsiveUtils.maxWidthDetail,
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('个人信息', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                // 姓 + 名：双列排列
                const Row(
                  children: [
                    Expanded(child: TextField(decoration: InputDecoration(labelText: '姓', prefixIcon: Icon(Icons.person_outline)))),
                    SizedBox(width: 16),
                    Expanded(child: TextField(decoration: InputDecoration(labelText: '名'))),
                  ],
                ),
                const SizedBox(height: 16),
                // 邮箱 + 手机：双列排列
                const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: '邮箱', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: '手机号', prefixIcon: Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                Text('地址信息', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                // 省 + 市：双列排列
                const Row(
                  children: [
                    Expanded(child: TextField(decoration: InputDecoration(labelText: '省/直辖市', prefixIcon: Icon(Icons.location_on_outlined)))),
                    SizedBox(width: 16),
                    Expanded(child: TextField(decoration: InputDecoration(labelText: '市/区'))),
                  ],
                ),
                const SizedBox(height: 16),
                const TextField(decoration: InputDecoration(labelText: '详细地址'), maxLines: 3),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 200,
                  child: TextField(decoration: InputDecoration(labelText: '邮政编码')),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(onPressed: () {}, child: const Text('取消')),
                      const SizedBox(width: 16),
                      FilledButton(onPressed: () {}, child: const Text('提交')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
