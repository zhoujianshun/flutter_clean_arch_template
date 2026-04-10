library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_request.freezed.dart';
part 'api_request.g.dart';

/// 分页请求参数
@freezed
abstract class PageRequest with _$PageRequest {
  const factory PageRequest({
    @Default(1) int pageNum,
    @Default(10) int pageSize,
  }) = _PageRequest;

  factory PageRequest.fromJson(Map<String, Object?> json) => _$PageRequestFromJson(json);
}
