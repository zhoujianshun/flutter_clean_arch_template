import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/models/pagination_action_result.dart';
import 'package:flutter_clean_arch_template/shared/models/pagination_state.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_empty_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 通用分页列表组件。
///
/// 内部统一管理 [EasyRefreshController]，自动处理：
/// - `finishRefresh` + `resetFooter`（刷新成功后重置加载状态）
/// - `finishLoad(IndicatorResult)`（基于 [PaginationActionResult] 明确通知 EasyRefresh）
///
/// 使用方只需提供 [onRefresh]、[onLoadMore] 回调并返回结果，
/// 无需手动管理 controller。
class PaginationList<T> extends StatefulWidget {
  const PaginationList({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    required this.onRetry,
    super.key,
    this.padding,
    this.separatorHeight,
    this.emptyBuilder,
    this.errorBuilder,
    this.resetFooterAfterRefreshSuccess = true,
  });

  final PaginationState<T> state;
  final PaginationActionCallback onRefresh;
  final PaginationActionCallback onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback onRetry;
  final EdgeInsets? padding;
  final double? separatorHeight;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(
    BuildContext context, {
    String? error,
    VoidCallback onRetry,
  })?
  errorBuilder;
  final bool resetFooterAfterRefreshSuccess;

  @override
  State<PaginationList<T>> createState() => _PaginationListState<T>();
}

class _PaginationListState<T> extends State<PaginationList<T>> {
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
          library: 'pagination_list',
          context: ErrorDescription('while executing pagination callback'),
        ),
      );
      return PaginationActionResult.fail(message: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    // 初始加载状态（首次进入，无数据）
    if (state.isLoading && state.items.isEmpty) {
      return _buildLoadingState();
    }

    // 错误状态（无数据）
    if (state.hasError && state.items.isEmpty) {
      return _buildErrorState();
    }

    Widget child;
    if (state.isEmpty) {
      child = _buildEmptyState();
    } else {
      child = ListView.separated(
        padding: widget.padding ?? EdgeInsets.all(12.w),
        itemCount: state.items.length,
        separatorBuilder: (_, _) => SizedBox(height: widget.separatorHeight ?? 8.w),
        itemBuilder: (context, index) => widget.itemBuilder(context, state.items[index], index),
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: EasyRefresh(
        controller: _controller,
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
        child: child,
      ),
    );
  }

  Widget _buildLoadingState() => const AppLoadingIndicator();

  Widget _buildErrorState() =>
      widget.errorBuilder?.call(
        context,
        error: widget.state.error,
        onRetry: widget.onRetry,
      ) ??
      AppErrorWidget(
        error: widget.state.error ?? '加载失败',
        onRetry: widget.onRetry,
      );

  Widget _buildEmptyState() => widget.emptyBuilder?.call(context) ?? const AppEmptyWidget(inScrollView: true);
}
