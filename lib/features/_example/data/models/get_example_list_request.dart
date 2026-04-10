import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_example_list_request.freezed.dart';
part 'get_example_list_request.g.dart';

@freezed
abstract class GetExampleListRequest with _$GetExampleListRequest {
  const factory GetExampleListRequest({
    required int pageNum,
    @Default(20) int pageSize,
  }) = _GetExampleListRequest;

  factory GetExampleListRequest.fromJson(Map<String, dynamic> json) => _$GetExampleListRequestFromJson(json);
}
