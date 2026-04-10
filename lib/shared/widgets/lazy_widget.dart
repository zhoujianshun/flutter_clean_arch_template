import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 懒加载页面包装器，支持页面缓存
///
/// 优点：
/// 1. 支持懒加载：只有在页面第一次被访问时才会创建对应的 Widget，节省内存和初始化开销
/// 2. 页面缓存：通过 AutomaticKeepAliveClientMixin，页面状态会被保留，切换时不会重新构建
/// 3. 适合多 Tab 应用：在 BottomNavigationBar 或 PageView 场景下，避免所有页面一次性初始化
///
/// 注意事项：
/// 1. 内存占用：所有访问过的页面都会被缓存，页面多时可能导致内存占用较高
/// 2. 生命周期管理：被缓存的页面不会被销毁，需要在页面内部自行管理资源释放
/// 3. 刷新机制：如需强制刷新，可配合 Key 使用或调用 refresh() 方法
///
/// 使用场景对比：
/// - 推荐使用 LazyWidget：多 Tab 应用，统一管理懒加载和缓存，简化页面代码
/// - 直接使用 AutomaticKeepAliveClientMixin：页面有特殊的生命周期或缓存需求
///
/// 使用示例：
/// ```dart
/// PageView(
///   children: [
///     LazyWidget(pageBuilder: () => HomePage()),
///     LazyWidget(
///       enableKeepAlive: false,  // 不缓存
///       pageBuilder: () => ProfilePage(),
///     ),
///   ],
/// )
/// ```
class LazyWidget extends StatefulWidget {
  const LazyWidget({
    required this.pageBuilder,
    this.enableKeepAlive = true,
    super.key,
  });

  /// 页面构建器，懒加载时调用
  final Widget Function() pageBuilder;

  /// 是否启用页面缓存，默认为 true
  /// 设置为 false 时，页面切换后会被销毁，下次访问时重新创建
  final bool enableKeepAlive;

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> with AutomaticKeepAliveClientMixin {
  Widget? _page;

  @override
  bool get wantKeepAlive => widget.enableKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build 以支持 keepAlive

    // 懒加载：只在第一次访问时创建页面
    _page ??= widget.pageBuilder();

    // 仅在 debug 模式下输出日志
    if (kDebugMode) {
      // debugPrint('LazyWidget build: ${widget.key}');
    }

    return _page!;
  }

  @override
  void didUpdateWidget(covariant LazyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果 keepAlive 状态变化，需要更新 keepAlive 状态
    if (oldWidget.enableKeepAlive != widget.enableKeepAlive) {
      updateKeepAlive();
    }

    // 如果 pageBuilder 发生变化，清空缓存以便重新构建
    if (oldWidget.pageBuilder != widget.pageBuilder) {
      _page = null;
    }
  }

  @override
  void dispose() {
    _page = null; // 清空缓存
    super.dispose();
  }

  /// 强制刷新页面（清空缓存，下次构建时重新创建）
  ///
  /// 使用示例：
  /// ```dart
  /// final lazyKey = GlobalKey<_LazyWidgetState>();
  ///
  /// LazyWidget(
  ///   key: lazyKey,
  ///   pageBuilder: () => MyPage(),
  /// )
  ///
  /// // 需要刷新时
  /// lazyKey.currentState?.refresh();
  /// ```
  void refresh() {
    if (mounted) {
      setState(() {
        _page = null;
      });
    }
  }
}
