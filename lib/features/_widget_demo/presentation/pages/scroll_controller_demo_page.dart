import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 6：ScrollController 滚动控制
///
/// ScrollController 的完整能力：
/// - 监听滚动位置、方向、是否在滚动中
/// - `animateTo` 平滑滚动到指定位置
/// - `jumpTo` 立即跳转
/// - 返回顶部 FAB 的显隐逻辑
/// - 滚动到指定 index（通过计算 offset）
@RoutePage()
class ScrollControllerDemoPage extends StatefulWidget {
  const ScrollControllerDemoPage({super.key});

  @override
  State<ScrollControllerDemoPage> createState() =>
      _ScrollControllerDemoPageState();
}

class _ScrollControllerDemoPageState extends State<ScrollControllerDemoPage> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _showBackToTop = false;
  String _scrollDirection = '静止';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final direction = _scrollController.position.userScrollDirection;

    setState(() {
      _scrollOffset = offset;
      _showBackToTop = offset > 300;
      _scrollDirection = switch (direction) {
        ScrollDirection.forward => '↓ 向下（手指下滑）',
        ScrollDirection.reverse => '↑ 向上（手指上滑）',
        ScrollDirection.idle => '静止',
      };
    });
  }

  void _scrollToTop() {
    unawaited(_scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    ));
  }

  void _scrollToPosition(double offset) {
    unawaited(_scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    ));
  }

  void _jumpToEnd() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('ScrollController'),
            expandedHeight: 120.h,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                alignment: Alignment.bottomLeft,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: Text(
                  'offset: ${_scrollOffset.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),

          // 状态面板
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('实时状态', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    _buildStatusRow('偏移量', '${_scrollOffset.toStringAsFixed(1)} px'),
                    _buildStatusRow('方向', _scrollDirection),
                    _buildStatusRow('返回顶部', _showBackToTop ? '显示' : '隐藏'),
                  ],
                ),
              ),
            ),
          ),

          // 控制按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  FilledButton.tonal(
                    onPressed: _scrollToTop,
                    child: const Text('animateTo(0)'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _scrollToPosition(1000),
                    child: const Text('animateTo(1000)'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _scrollToPosition(2000),
                    child: const Text('animateTo(2000)'),
                  ),
                  FilledButton.tonal(
                    onPressed: _jumpToEnd,
                    child: const Text('jumpTo(end)'),
                  ),
                ],
              ),
            ),
          ),

          // 说明
          SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.all(16.w),
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('关键 API', style: theme.textTheme.titleSmall),
                    SizedBox(height: 8.h),
                    const Text(
                      '• controller.offset → 当前滚动偏移量\n'
                      '• controller.position.userScrollDirection → 用户滚动方向\n'
                      '• controller.animateTo(offset, duration, curve) → 平滑滚动\n'
                      '• controller.jumpTo(offset) → 立即跳转（无动画）\n'
                      '• controller.position.maxScrollExtent → 最大可滚动距离\n'
                      '• addListener / removeListener → 监听滚动事件',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 长列表
          SliverList.builder(
            itemCount: 50,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('列表项 ${index + 1}'),
              subtitle: Text('offset ≈ ${(index * 56).toStringAsFixed(0)} px'),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _showBackToTop ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: _scrollToTop,
          child: const Icon(Icons.arrow_upward),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
          )),
        ],
      ),
    );
  }
}
