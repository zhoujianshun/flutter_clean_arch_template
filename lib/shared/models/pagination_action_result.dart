import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';

/// 分页动作状态。
enum PaginationActionStatus {
  /// 请求成功，且可以继续加载更多（或本次为刷新）。
  success,

  /// 没有更多数据。
  noMore,

  /// 请求失败。
  fail,
}

/// 分页动作返回值。
///
/// 用于明确通知 EasyRefresh 本次 refresh/load 的最终结果，
/// 避免通过外部状态推断而导致指示器无法结束。
class PaginationActionResult {
  const PaginationActionResult._({
    required this.status,
    this.message,
  });

  const PaginationActionResult.success({String? message})
    : this._(status: PaginationActionStatus.success, message: message);

  const PaginationActionResult.noMore({String? message})
    : this._(status: PaginationActionStatus.noMore, message: message);

  const PaginationActionResult.fail({String? message}) : this._(status: PaginationActionStatus.fail, message: message);

  final PaginationActionStatus status;
  final String? message;

  IndicatorResult get loadIndicatorResult {
    switch (status) {
      case PaginationActionStatus.success:
        return IndicatorResult.success;
      case PaginationActionStatus.noMore:
        return IndicatorResult.noMore;
      case PaginationActionStatus.fail:
        return IndicatorResult.fail;
    }
  }

  IndicatorResult get refreshIndicatorResult =>
      status == PaginationActionStatus.fail ? IndicatorResult.fail : IndicatorResult.success;

  /// 非失败状态（包含 success 和 noMore），用于判断刷新后是否重置 footer。
  bool get isRefreshCompleted => status == PaginationActionStatus.success || status == PaginationActionStatus.noMore;
}

typedef PaginationActionCallback = FutureOr<PaginationActionResult> Function();
