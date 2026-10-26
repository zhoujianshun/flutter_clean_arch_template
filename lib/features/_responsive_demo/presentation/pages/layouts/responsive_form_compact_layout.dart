import 'package:flutter/material.dart';
/// Compact form layout for phones.
class ResponsiveFormCompactLayout extends StatelessWidget {
  const ResponsiveFormCompactLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('responsive_form_compact_scroll'),
      padding: EdgeInsets.all(
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('个人信息', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              labelText: '姓',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: '名')),
          SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: '邮箱',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: '手机号',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24),
          Text('地址信息', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: '省/直辖市',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: '市/区')),
          SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: '详细地址'),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: '邮政编码')),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(onPressed: () {}, child: const Text('提交')),
          ),
        ],
      ),
    );
  }
}
