import 'package:flutter_clean_arch_template/shared/models/api/api_success_policy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// 分页数据模型
@Freezed(genericArgumentFactories: true)
abstract class PaginatedData<T> with _$PaginatedData<T> {
  // 私有构造函数
  const factory PaginatedData({
    required List<T> rows,
    required int total,
    @Default(false) bool hasNext,
    @Default(false) bool hasPrevious,
    int? currentPage,
    int? pageSize,
  }) = _PaginatedData<T>;
  const PaginatedData._();

  factory PaginatedData.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PaginatedDataFromJson(json, fromJsonT);
}

/// 统一的 API 响应模型
@freezed
abstract class ApiResponse<T> with _$ApiResponse<T> {
  // 私有构造函数，用于支持自定义 getter

  const factory ApiResponse({
    required String msg,
    required int code,
    T? data,
  }) = _ApiResponse<T>;

  const ApiResponse._();

  // const factory ApiResponse.data({
  //   required String msg,
  //   required int code,
  //   required T data,
  // }) = _ApiResponseData<T>;

  // factory ApiResponse.pageable({
  //   required String msg,
  //   required int code,
  //   required PageableData<T> data,
  // }) = _ApiResponsePageable<PageableData<T>>;

  // factory ApiResponse.fromJsonData(Map<String, dynamic> json, T Function(Object?) fromJsonT) {
  //   return ApiResponse.fromJson(json, fromJsonT);
  // }

  // factory ApiResponse.fromJsonPageable(Map<String, dynamic> pageableJson, T Function(Object?) fromJsonT) {
  //   return ApiResponse.fromJson(
  //       pageableJson, (json) => PageableData.fromJson(json! as Map<String, dynamic>, fromJsonT));
  // }

  /// 智能判断 JSON 类型并创建相应的实例
  ///
  /// 对 `msg` 和 `code` 做容错处理，兼容后端返回非标准类型的情况。
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) {
    final msg = json['msg']?.toString() ?? json['message']?.toString() ?? '';
    final rawCode = json['code'];
    final code = rawCode is int
        ? rawCode
        : rawCode is String
        ? int.tryParse(rawCode) ?? -1
        : -1;

    // 检查是否包含分页相关字段
    if (json.containsKey('rows') ||
        json.containsKey('total') ||
        json.containsKey('hasNext') ||
        json.containsKey('hasPrevious')) {
      // 对于分页数据，直接将 JSON 转换为 PageableData
      final pageableJson = {
        'rows': json['rows'] ?? <dynamic>[],
        'total': json['total'] ?? 0,
        'hasNext': json['hasNext'] ?? false,
        'hasPrevious': json['hasPrevious'] ?? false,
      };
      // 使用 fromJsonT 处理整个分页对象
      return ApiResponse<T>(
        msg: msg,
        code: code,
        data: fromJsonT(pageableJson),
      );
    } else {
      // 普通数据响应
      return ApiResponse<T>(
        msg: msg,
        code: code,
        data: json['data'] != null ? fromJsonT(json['data']) : null,
      );
    }
  }

  /// 创建成功响应
  factory ApiResponse.success({
    required T data,
    String message = '操作成功',
    int? code,
  }) {
    return ApiResponse<T>(
      msg: message,
      data: data,
      code: code ?? 200,
    );
  }

  /// 创建失败响应
  factory ApiResponse.failure({
    required String message,
    int? code,
    T? data,
  }) {
    return ApiResponse<T>(
      msg: message,
      data: data,
      code: code ?? 400,
    );
  }

  /// 创建分页成功响应 - 返回 `ApiResponse<PageableData<T>>`
  static ApiResponse<PaginatedData<T>> pageableSuccess<T>({
    required List<T> rows,
    required int total,
    String message = '操作成功',
    int? code,
    bool? hasNext,
    bool? hasPrevious,
    // int? currentPage,
    // int? pageSize,
  }) {
    final pageableData = PaginatedData<T>(
      rows: rows,
      total: total,
      hasNext: hasNext ?? false,
      hasPrevious: hasPrevious ?? false,
      // currentPage: currentPage,
      // pageSize: pageSize,
    );
    return ApiResponse<PaginatedData<T>>(
      msg: message,
      code: code ?? 200,
      data: pageableData,
    );
  }

  /// 获取消息
  String get message => msg;

  /// 获取状态码
  int get statusCode => code;

  /// 是否成功（通过 [ApiSuccessPolicy] 判断，默认 code == 200）
  bool get isSuccess => ApiSuccessPolicy.instance.isSuccess(code);

  /// 是否失败
  bool get isFailure => !isSuccess;

  /// 是否有数据
  bool get hasData => data != null;
}

/// PaginatedData 扩展方法
extension PaginatedDataExtension<T> on PaginatedData<T> {
  /// 是否有数据
  bool get hasData => rows.isNotEmpty;

  /// 计算总页数
  int totalPages([int defaultPageSize = 10]) {
    final size = pageSize ?? defaultPageSize;
    return (total / size).ceil();
  }

  /// 当前页数据数量
  int get currentPageSize => rows.length;

  /// 是否为空页面
  bool get isEmpty => rows.isEmpty;

  /// 是否为最后一页
  bool get isLastPage => !hasNext;

  /// 是否为第一页
  bool get isFirstPage => !hasPrevious;
}

/// ApiResponse 分页数据扩展方法
extension ApiResponsePageResponseExtension<T> on ApiResponse<PaginatedData<T>> {
  /// 获取数据列表
  List<T> get rows => data?.rows ?? [];

  /// 获取总数
  int get total => data?.total ?? 0;

  /// 是否有下一页
  bool get hasNextPage => data?.hasNext ?? false;

  /// 是否有上一页
  bool get hasPreviousPage => data?.hasPrevious ?? false;

  /// 当前页数据数量
  int get currentPageSize => data?.currentPageSize ?? 0;

  /// 总页数
  int totalPages([int defaultPageSize = 10]) => data?.totalPages(defaultPageSize) ?? 0;
}

@freezed
abstract class FileUploadResult with _$FileUploadResult {
  const factory FileUploadResult({
    required String url,
    required String fileName,
    required String ossId,
  }) = _FileUploadResult;

  factory FileUploadResult.fromJson(Map<String, dynamic> json) => _$FileUploadResultFromJson(json);
}
