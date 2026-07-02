import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_utils.dart';

/// 自适应网格画廊示例
///
/// 演示如何根据可用宽度自动调整网格列数：
/// - **手机**：2 列
/// - **平板竖屏**：3 列
/// - **平板横屏/桌面**：4 列
///
/// 使用 [SliverGridDelegateWithMaxCrossAxisExtent] 可以实现更流畅的自适应，
/// 但本示例使用 [ResponsiveUtils.itemGridColumns] 来演示断点控制的方式。
@RoutePage()
class ResponsiveGalleryPage extends StatelessWidget {
  const ResponsiveGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自适应网格画廊')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = ResponsiveUtils.itemGridColumns(constraints);
          final spacing = ResponsiveUtils.valueOf<double>(
            constraints,
            compact: 8,
            medium: 12,
            expanded: 16,
          );

          return GridView.builder(
            padding: EdgeInsets.all(spacing),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: _galleryItems.length,
            itemBuilder: (context, index) {
              final item = _galleryItems[index];
              return _GalleryCard(item: item);
            },
          );
        },
      ),
    );
  }
}

// ── 模拟数据 ──────────────────────────────────────────────────────────────

class _GalleryItem {
  const _GalleryItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String description;
}

const _galleryItems = [
  _GalleryItem(title: '风景', icon: Icons.landscape, color: Colors.green, description: '山川湖海'),
  _GalleryItem(title: '建筑', icon: Icons.apartment, color: Colors.blue, description: '城市天际线'),
  _GalleryItem(title: '美食', icon: Icons.restaurant, color: Colors.orange, description: '舌尖美味'),
  _GalleryItem(title: '动物', icon: Icons.pets, color: Colors.brown, description: '自然生灵'),
  _GalleryItem(title: '旅行', icon: Icons.flight, color: Colors.indigo, description: '环游世界'),
  _GalleryItem(title: '运动', icon: Icons.sports_basketball, color: Colors.red, description: '活力生活'),
  _GalleryItem(title: '音乐', icon: Icons.music_note, color: Colors.purple, description: '声音艺术'),
  _GalleryItem(title: '科技', icon: Icons.computer, color: Colors.teal, description: '数字时代'),
  _GalleryItem(title: '艺术', icon: Icons.palette, color: Colors.pink, description: '创意灵感'),
  _GalleryItem(title: '阅读', icon: Icons.book, color: Colors.amber, description: '知识海洋'),
  _GalleryItem(title: '电影', icon: Icons.movie, color: Colors.cyan, description: '光影世界'),
  _GalleryItem(title: '游戏', icon: Icons.sports_esports, color: Colors.lime, description: '虚拟冒险'),
];

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.item});
  final _GalleryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('点击了「${item.title}」'), duration: const Duration(seconds: 1)),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 32, color: item.color),
            ),
            const SizedBox(height: 12),
            Text(item.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(item.description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
