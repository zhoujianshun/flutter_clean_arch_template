import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

/// Tablet form layout with grouped card and two-column fields.
class ResponsiveFormTabletLayout extends StatelessWidget {
  const ResponsiveFormTabletLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('responsive_form_tablet_scroll'),
      child: ContentConstraint(
        maxWidth: ResponsiveTokens.maxWidthDetail,
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('个人信息', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: '姓',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: '名'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: '邮箱',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: '手机号',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
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
                const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: '省/直辖市',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(labelText: '市/区'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(labelText: '详细地址'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(labelText: '邮政编码'),
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(onPressed: () {}, child: const Text('取消')),
                      SizedBox(
                        width: ResponsiveTokens.size(
                          16,
                          medium: 16,
                          expanded: 16,
                        ),
                      ),
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
