import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

/// Master-Detail 详情页（AutoRoute 版本）
///
/// 从 `MasterDetailPage` 中提取的独立路由页面，接收路由参数。
/// 仅在手机模式下作为全屏页面使用，平板模式下详情面板直接内嵌在分栏中。
///
/// 此页面演示了如何将 Master-Detail 的详情视图注册为 AutoRoute 路由，
/// 使其支持路由守卫、deep link、统一转场动画等 AutoRoute 特性。
@RoutePage()
class MasterDetailDetailPage extends StatelessWidget {
  const MasterDetailDetailPage({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    super.key,
  });

  final String sender;
  final String subject;
  final String preview;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: ContentConstraint(
        maxWidth: ResponsiveTokens.maxWidthDetail,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      sender[0],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(subject, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(
                '$preview\n\n'
                '这是一段示例正文内容，用于展示详情面板在不同屏幕尺寸下的显示效果。'
                '在手机上，这个面板会以全屏页面的形式展示；'
                '在平板上，它会显示在右侧的详情区域中，与左侧的列表并排显示。\n\n'
                '本页面通过 AutoRoute 注册为独立路由，相比 Navigator.push 的优势：\n'
                '• 经过 AuthGuard / DebouncerGuard 等路由守卫\n'
                '• 支持 deep link（可通过 URL 直接访问）\n'
                '• 统一的转场动画（遵循 AppRouter.defaultRouteType）\n'
                '• 在路由观察器（observer）中可追踪',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
