import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/features/_example/data/datasources/example_mock_datasource.dart';
import 'package:flutter_clean_arch_template/features/_example/data/datasources/example_remote_datasource.dart';
import 'package:flutter_clean_arch_template/features/_example/data/models/example_mapper.dart';
import 'package:flutter_clean_arch_template/features/_example/data/models/get_example_list_request.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/repositories/example_repository.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';
import 'package:injectable/injectable.dart';

/// 示例 Repository 实现（Data 层）
///
/// 职责：
/// 1. 调用 [ExampleRemoteDataSource] 获取 DTO 数据
/// 2. 将 DTO 转换为 Domain Entity（通过 [ExampleItemDtoMapper]）
/// 3. 返回 [Either<Failure, T>] 给 Presentation 层
///
/// 当 `AppConfig.mockData` 为 true 时，使用 [ExampleMockDataSource] 返回本地模拟数据。
@Singleton(as: ExampleRepository)
class ExampleRepositoryImpl implements ExampleRepository {
  ExampleRepositoryImpl(this._remoteDataSource);

  final ExampleRemoteDataSource _remoteDataSource;
  final ExampleMockDataSource _mockDataSource = ExampleMockDataSource();

  @override
  Future<Either<Failure, PaginatedData<ExampleItem>>> getList({
    required int pageNum,
    int pageSize = 20,
  }) async {
    final request = GetExampleListRequest(
      pageNum: pageNum,
      pageSize: pageSize,
    );

    final result = AppConfig.mockData
        ? await _mockDataSource.getList(request)
        : await _remoteDataSource.getList(request);

    return result.map((paginatedDto) {
      AppLogger.debug(
        'ExampleRepository.getList: '
        'page=$pageNum, fetched=${paginatedDto.rows.length}, '
        'total=${paginatedDto.total}',
      );

      return PaginatedData<ExampleItem>(
        rows: paginatedDto.rows.toEntities(),
        total: paginatedDto.total,
        hasNext: paginatedDto.hasNext,
        hasPrevious: paginatedDto.hasPrevious,
        currentPage: pageNum,
        pageSize: pageSize,
      );
    });
  }

  @override
  Future<Either<Failure, ExampleItem>> getDetail(String id) async {
    final result = AppConfig.mockData ? await _mockDataSource.getDetail(id) : await _remoteDataSource.getDetail(id);
    return result.map((dto) => dto.toEntity());
  }
}
