import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/network/base_api.dart';
import 'package:flutter_clean_arch_template/features/_example/data/models/example_item_dto.dart';
import 'package:flutter_clean_arch_template/features/_example/data/models/get_example_list_request.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';
import 'package:injectable/injectable.dart';

/// 示例功能的远程数据源
///
/// 继承 [BaseAPI] 获得统一的错误处理和 Either 返回。
/// 真实项目中此处调用 [apiClient] 发起网络请求。
@singleton
class ExampleRemoteDataSource extends BaseAPI {
  ExampleRemoteDataSource(super.apiClient);

  static const _basePath = '/examples';

  Future<Either<Failure, PaginatedData<ExampleItemDto>>> getList(
    GetExampleListRequest request,
  ) async {
    return handlePaginatedApiCall(
      apiClient.get(
        _basePath,
        queryParameters: request.toJson(),
      ),
      ExampleItemDto.fromJson,
      logTag: 'ExampleRemoteDataSource.getList',
    );
  }

  Future<Either<Failure, ExampleItemDto>> getDetail(String id) async {
    return handleApiCall(
      apiClient.get('$_basePath/$id'),
      ExampleItemDto.fromJson,
      logTag: 'ExampleRemoteDataSource.getDetail',
    );
  }
}
