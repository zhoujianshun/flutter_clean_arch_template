import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 3：拉伸效果（stretch）
///
/// 关键属性：
/// - `stretch: true`：在列表顶部继续下拉时，背景图拉伸放大
/// - `stretchTriggerOffset`：触发 onStretchTrigger 回调的偏移量
/// - `onStretchTrigger`：拉伸超过阈值时触发（可用于刷新）
///
/// 业务场景：iOS 风格弹性拉伸、下拉刷新指示
@RoutePage()
class SliverStretchDemoPage extends StatefulWidget {
  const SliverStretchDemoPage({super.key});

  @override
  State<SliverStretchDemoPage> createState() => _SliverStretchDemoPageState();
}

class _SliverStretchDemoPageState extends State<SliverStretchDemoPage> {
  String _stretchStatus = '尚未触发拉伸';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 300.h,
            stretchTriggerOffset: 150,
            onStretchTrigger: () async {
              setState(() => _stretchStatus = '拉伸触发！正在刷新...');
              await Future<void>.delayed(const Duration(seconds: 1));
              if (mounted) {
                setState(() => _stretchStatus = '刷新完成 ✓');
              }
            },
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('拉伸效果'),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.landscape_outlined,
                        size: 80,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '向下拉伸观察效果',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 状态指示
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: _stretchStatus.contains('触发')
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Icon(
                      _stretchStatus.contains('完成')
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: _stretchStatus.contains('触发')
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    Text(_stretchStatus, style: theme.textTheme.bodyMedium),
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
                    Text('关键属性', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• stretch: true → 开启拉伸效果\n'
                      '• stretchTriggerOffset: 150 → 拉伸超过 150px 触发回调\n'
                      '• onStretchTrigger → 可用于触发刷新操作\n\n'
                      'StretchMode 可组合使用：\n'
                      '• zoomBackground → 背景图放大\n'
                      '• blurBackground → 背景图模糊\n'
                      '• fadeTitle → 标题淡出',
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverList.builder(
            itemCount: 25,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('内容项 ${index + 1}'),
              subtitle: const Text('在顶部继续下拉体验拉伸效果'),
            ),
          ),
        ],
      ),
    );
  }
}
