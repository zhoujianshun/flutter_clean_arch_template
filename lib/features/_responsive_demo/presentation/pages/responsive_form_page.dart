import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/layouts/responsive_form_compact_layout.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/layouts/responsive_form_tablet_layout.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';

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
      body: const StatefulAdaptiveBuilder(
        compact: ResponsiveFormCompactLayout(),
        medium: ResponsiveFormTabletLayout(),
      ),
    );
  }
}
