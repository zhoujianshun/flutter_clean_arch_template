import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/features/_example/data/models/example_item_dto.dart';
import 'package:flutter_clean_arch_template/features/_example/data/models/get_example_list_request.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';

/// 示例功能的 Mock 数据源
///
/// 提供本地模拟数据，无需真实后端服务即可运行项目。
/// 通过 `AppConfig.mockData` 控制是否启用。
class ExampleMockDataSource {
  static final List<ExampleItemDto> _mockItems = List.generate(
    25,
    (i) => ExampleItemDto(
      id: '${i + 1}',
      title: '示例项目 ${i + 1}',
      description: '这是第 ${i + 1} 个示例项目的详细描述，用于展示列表和详情页面的数据。',
      isCompleted: i % 3 == 0,
      createdAt: DateTime.now().subtract(Duration(days: 25 - i)).toIso8601String(),
    ),
  );

  Future<Either<Failure, PaginatedData<ExampleItemDto>>> getList(
    GetExampleListRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    AppLogger.debug('[MOCK] ExampleMockDataSource.getList: page=${request.pageNum}, size=${request.pageSize}');

    final start = (request.pageNum - 1) * request.pageSize;
    final end = (start + request.pageSize).clamp(0, _mockItems.length);

    if (start >= _mockItems.length) {
      return Right(
        PaginatedData<ExampleItemDto>(
          rows: [],
          total: _mockItems.length,
          hasPrevious: request.pageNum > 1,
          currentPage: request.pageNum,
          pageSize: request.pageSize,
        ),
      );
    }

    final pageItems = _mockItems.sublist(start, end);
    return Right(
      PaginatedData<ExampleItemDto>(
        rows: pageItems,
        total: _mockItems.length,
        hasNext: end < _mockItems.length,
        hasPrevious: request.pageNum > 1,
        currentPage: request.pageNum,
        pageSize: request.pageSize,
      ),
    );
  }

  Future<Either<Failure, ExampleItemDto>> getDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    AppLogger.debug('[MOCK] ExampleMockDataSource.getDetail: id=$id');

    try {
      final item = _mockItems.firstWhere((e) => e.id == id);
      return Right(item);
    } catch (_) {
      return const Left(Failure.unknown(message: '[MOCK] Item not found'));
    }
  }
}
