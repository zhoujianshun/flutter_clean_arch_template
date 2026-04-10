import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_state.freezed.dart';
part 'pagination_state.g.dart';

/// 分页请求参数
// @freezed
// abstract class PaginationParams with _$PaginationParams {
//   const factory PaginationParams({
//     /// 页码，从1开始
//     @Default(1) int page,

//     /// 每页数量
//     @Default(20) int pageSize,

//     /// 是否是刷新操作
//     @Default(false) bool isRefresh,
//   }) = _PaginationParams;

//   factory PaginationParams.fromJson(Map<String, dynamic> json) => _$PaginationParamsFromJson(json);
// }

/// 分页状态
@Freezed(genericArgumentFactories: true)
abstract class PaginationState<T> with _$PaginationState<T> {
  const factory PaginationState({
    /// 所有数据列表
    @Default([]) List<T> items,

    /// 当前页码
    @Default(1) int currentPage,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否正在加载更多
    @Default(false) bool isLoadingMore,

    /// 是否有更多数据
    @Default(true) bool hasMore,

    /// 错误信息
    String? error,

    /// 总数量
    @Default(0) int total,

    /// 刷新状态标记，用于通知UI刷新完成
    @Default(0) int refreshTimestamp,
  }) = _PaginationState<T>;

  factory PaginationState.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PaginationStateFromJson(json, fromJsonT);
}

/// 分页状态扩展方法
extension PaginationStateExtensions<T> on PaginationState<T> {
  /// 是否为空状态
  bool get isEmpty => items.isEmpty && !isLoading && error == null;

  /// 是否为错误状态
  bool get hasError => error != null;

  /// 是否可以加载更多
  bool get canLoadMore => hasMore && !isLoading && !isLoadingMore;
}

/// 分页响应数据
// @Freezed(genericArgumentFactories: true)
// abstract class PaginationResponse<T> with _$PaginationResponse<T> {
//   const factory PaginationResponse({
//     /// 当前页数据
//     required List<T> data,

//     /// 当前页码
//     required int currentPage,

//     /// 每页数量
//     required int pageSize,

//     /// 总数量
//     required int total,

//     /// 总页数
//     required int totalPages,

//     /// 是否有下一页
//     required bool hasNext,

//     /// 是否有上一页
//     required bool hasPrevious,
//   }) = _PaginationResponse<T>;

//   factory PaginationResponse.fromJson(
//     Map<String, dynamic> json,
//     T Function(Object?) fromJsonT,
//   ) =>
//       _$PaginationResponseFromJson(json, fromJsonT);
// }
