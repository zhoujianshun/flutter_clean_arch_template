import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式图文详情示例
///
/// 演示图文混排内容在不同屏幕上的布局差异：
/// - **手机**：图片在上，文字在下，纵向滚动
/// - **平板**：图片在左（固定宽度），文字在右（弹性宽度），横向并排
///
/// 适用场景：商品详情、文章阅读、个人简介等图文并茂的页面。
@RoutePage()
class ResponsiveArticlePage extends StatelessWidget {
  const ResponsiveArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('图文详情示例')),
      body: AdaptiveLayoutBuilder(
        compact: (constraints) => _CompactArticle(constraints: constraints),
        medium: (constraints) => _MediumArticle(constraints: constraints),
      ),
    );
  }
}

/// 手机布局：图片上 + 文字下
class _CompactArticle extends StatelessWidget {
  const _CompactArticle({required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图片区域
          _buildImagePlaceholder(context, height: 220.h),
          // 文字内容
          Padding(
            padding: EdgeInsets.all(16.w),
            child: _buildArticleContent(context),
          ),
        ],
      ),
    );
  }
}

/// 平板布局：图片左 + 文字右
class _MediumArticle extends StatelessWidget {
  const _MediumArticle({required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final imageWidth = ResponsiveUtils.isExpanded(constraints) ? 420.0 : 340.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧图片区域（固定宽度，可滚动多张图）
        SizedBox(
          width: imageWidth,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildImagePlaceholder(context, height: 300),
              const SizedBox(height: 16),
              // 缩略图网格
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: List.generate(
                  6,
                  (i) => _buildSmallImagePlaceholder(context, i),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // 右侧文字内容
        Expanded(
          child: ContentConstraint(
            maxWidth: ResponsiveUtils.maxWidthDetail,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildArticleContent(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 共享组件 ──────────────────────────────────────────────────────────────

Widget _buildImagePlaceholder(BuildContext context, {required double height}) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.tertiaryContainer,
        ],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(height: 8),
          Text(
            '商品主图',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSmallImagePlaceholder(BuildContext context, int index) {
  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: colors[index % colors.length].withValues(alpha: 0.15),
    ),
    child: Center(
      child: Icon(Icons.image_outlined, color: colors[index % colors.length], size: 20),
    ),
  );
}

Widget _buildArticleContent(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 标题 + 价格
      Text('Flutter 整洁架构模板', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('¥ 199.00', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),

      // 标签
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildTag(context, '热门', Colors.red),
          _buildTag(context, '限时优惠', Colors.orange),
          _buildTag(context, '包邮', Colors.green),
        ],
      ),
      const SizedBox(height: 24),

      // 规格信息
      _buildInfoRow(context, '规格', 'Enterprise 版'),
      const Divider(height: 32),
      _buildInfoRow(context, '支持平台', 'iOS / Android / Web'),
      const Divider(height: 32),
      _buildInfoRow(context, '架构模式', 'Clean Architecture + DDD'),
      const Divider(height: 32),
      _buildInfoRow(context, '状态管理', 'Riverpod 3.0'),
      const SizedBox(height: 24),

      // 详情描述
      Text('商品详情', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Text(
        '这是一个完整的 Flutter 整洁架构项目模板，包含了企业级应用开发所需的全部基础设施：'
        '认证系统、网络层、主题切换、国际化、日志系统、错误处理、路由管理等。\n\n'
        '本页面演示了"图文详情"这一经典布局在手机和平板上的差异：\n'
        '• 手机上图片在顶部全宽展示，文字内容在下方纵向排列\n'
        '• 平板上图片固定在左侧，右侧为可滚动的文字详情区域\n'
        '• 右侧文字区域使用 ContentConstraint 限制最大阅读宽度\n\n'
        '这种布局适用于电商商品详情、文章阅读、个人简介等场景。',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
      ),
      const SizedBox(height: 32),

      // 底部按钮
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.favorite_outline),
              label: const Text('收藏'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(onPressed: () {}, child: const Text('立即购买')),
          ),
        ],
      ),
    ],
  );
}

Widget _buildTag(BuildContext context, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(text, style: TextStyle(fontSize: 12, color: color)),
  );
}

Widget _buildInfoRow(BuildContext context, String label, String value) {
  return Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
      ),
      Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
    ],
  );
}
