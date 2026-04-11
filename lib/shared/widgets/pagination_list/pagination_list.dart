import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/models/pagination_state.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_empty_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 通用消息列表视图组件
class PaginationList<T> extends StatelessWidget {
  const PaginationList({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    required this.onRetry,
    super.key,
    this.controller,
    this.padding,
    this.emptyBuilder,
    this.errorBuilder,
  });

  final PaginationState<T> state;

  final EasyRefreshController? controller;

  ///
  // ignore: strict_raw_type
  final FutureOr Function()? onRefresh;

  ///
  // ignore: strict_raw_type
  final FutureOr Function()? onLoadMore;

  ///
  final Widget Function(BuildContext context, T item) itemBuilder;

  ///
  final VoidCallback onRetry;

  ///
  final EdgeInsets? padding;

  ///
  final WidgetBuilder? emptyBuilder;

  ///
  final Widget Function(BuildContext context, {String? error, VoidCallback onRetry})? errorBuilder;

  @override
  Widget build(BuildContext context) {
    Widget? child;

    // 初始加载状态
    if (state.isLoading && state.items.isEmpty) {
      return _buildLoadingState(context);
    }

    // 错误状态
    if (state.hasError && state.items.isEmpty) {
      return _buildErrorState(context);
    }

    // 空状态
    if (state.isEmpty) {
      child = _buildEmptyState(context);
    } else {
      child = ListView.separated(
        padding: padding ?? EdgeInsets.all(12.w),
        itemCount: state.items.length,
        separatorBuilder: (context, index) {
          return SizedBox(height: 8.w);
        },
        itemBuilder: (context, index) {
          final item = state.items[index];
          return itemBuilder(context, item);
        },
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: EasyRefresh(
        controller: controller,
        onRefresh: onRefresh,
        onLoad: onLoadMore,
        child: child,
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState(BuildContext context) {
    return const AppLoadingIndicator();
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context) {
    return errorBuilder?.call(context, error: state.error, onRetry: onRetry) ??
        AppErrorWidget(
          error: state.error ?? '加载失败',
          onRetry: onRetry,
        );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return emptyBuilder?.call(context) ??
        const AppEmptyWidget(
          inScrollView: true,
        );
  }
}
