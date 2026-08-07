import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/models/pagination_action_result.dart';
import 'package:flutter_clean_arch_template/shared/models/pagination_state.dart';

/// 通用分页 Sliver 视图，将 EasyRefresh 与 CustomScrollView 结合。
///
/// 内部统一管理 [EasyRefreshController]，通过回调返回的
/// [PaginationActionResult] 明确结束 refresh/load 指示器，
/// 使用方只需提供 [slivers] 列表和刷新/加载回调。
class PaginationSliverView<T> extends StatefulWidget {
  const PaginationSliverView({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.slivers,
    super.key,
    this.scrollController,
    this.triggerAxis = Axis.vertical,
    this.resetFooterAfterRefreshSuccess = true,
  });

  final PaginationState<T> state;
  final PaginationActionCallback onRefresh;
  final PaginationActionCallback onLoadMore;
  final List<Widget> slivers;
  final ScrollController? scrollController;
  final Axis triggerAxis;
  final bool resetFooterAfterRefreshSuccess;

  @override
  State<PaginationSliverView<T>> createState() => _PaginationSliverViewState<T>();
}

class _PaginationSliverViewState<T> extends State<PaginationSliverView<T>> {
  late final EasyRefreshController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<PaginationActionResult> _runAction(
    PaginationActionCallback callback,
  ) async {
    try {
      return await callback();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'pagination_sliver_view',
          context: ErrorDescription('while executing pagination callback'),
        ),
      );
      return PaginationActionResult.fail(message: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh.builder(
      controller: _controller,
      triggerAxis: widget.triggerAxis,
      onRefresh: () async {
        final result = await _runAction(widget.onRefresh);
        if (!mounted) return;
        _controller.finishRefresh(result.refreshIndicatorResult);
        // 官方文档描述："Reset after refresh when no more deactivation is loaded"。这意味着当 finishRefresh() 被调用后，EasyRefresh 内部已经会自动 resetFooter
        // if (widget.resetFooterAfterRefreshSuccess && result.isRefreshCompleted) {
        //   _controller.resetFooter();
        // }
      },
      onLoad: () async {
        final result = await _runAction(widget.onLoadMore);
        if (!mounted) return;
        _controller.finishLoad(result.loadIndicatorResult);
      },
      childBuilder: (context, physics) {
        return CustomScrollView(
          controller: widget.scrollController,
          physics: physics,
          slivers: widget.slivers,
        );
      },
    );
  }
}
