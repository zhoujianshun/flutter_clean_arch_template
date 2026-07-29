import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 5：渐变透明背景
///
/// 核心技巧：
/// - 初始状态 AppBar 完全透明，背景图全屏展示
/// - 通过 `NotificationListener<ScrollNotification>` 监听滚动位置
/// - 动态计算 AppBar 背景色的透明度
/// - 同时动态切换 StatusBar 图标颜色（深/浅）
///
/// 业务场景：个人主页、活动页、Landing Page
@RoutePage()
class SliverFadeDemoPage extends StatefulWidget {
  const SliverFadeDemoPage({super.key});

  @override
  State<SliverFadeDemoPage> createState() => _SliverFadeDemoPageState();
}

class _SliverFadeDemoPageState extends State<SliverFadeDemoPage> {
  double _opacity = 0;
  static const double _expandedHeight = 320;

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      const maxScroll = _expandedHeight - kToolbarHeight;
      final newOpacity = (pixels / maxScroll).clamp(0, 1).toDouble();
      if (newOpacity != _opacity) {
        // 延迟到下一帧更新，避免在布局阶段调用 setState 导致
        // "Build scheduled during frame" 错误
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _opacity = newOpacity);
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _opacity > 0.5;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: _expandedHeight,
              backgroundColor: theme.colorScheme.surface.withValues(alpha: _opacity),
              foregroundColor: isDark
                  ? theme.colorScheme.onSurface
                  : Colors.white,
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _opacity > 0.7 ? 1 : 0,
                child: const Text('个人主页'),
              ),
              systemOverlayStyle: isDark
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景渐变
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),

                    // 用户信息
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.h),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          const Text(
                            '张三',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Flutter 开发者 · LV.8',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // 统计行
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStat('关注', '128'),
                              _buildDivider(),
                              _buildStat('粉丝', '1.2k'),
                              _buildDivider(),
                              _buildStat('获赞', '3.6k'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 透明度指示
            SliverToBoxAdapter(
              child: Card(
                margin: EdgeInsets.all(16.w),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      const Text('当前透明度：'),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _opacity,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text('${(_opacity * 100).toInt()}%'),
                    ],
                  ),
                ),
              ),
            ),

            // 属性说明
            SliverToBoxAdapter(
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('实现要点', style: theme.textTheme.titleSmall),
                      SizedBox(height: 8.h),
                      const Text(
                        '• NotificationListener<ScrollNotification> 监听滚动\n'
                        '• opacity = (pixels / maxScroll).clamp(0, 1)\n'
                        '• backgroundColor: color.withOpacity(opacity)\n'
                        '• 标题在 opacity > 0.7 时才显示\n'
                        '• systemOverlayStyle 随透明度切换深/浅图标',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 模拟内容
            SliverList.builder(
              itemCount: 20,
              itemBuilder: (context, index) => Card(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text('动态 #${index + 1}'),
                  subtitle: const Text('这是一条动态内容...'),
                  trailing: Text(
                    '${index + 1}小时前',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}
