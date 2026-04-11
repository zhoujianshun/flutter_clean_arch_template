import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';

/// 示例功能的 Repository 接口（Domain 层）
///
/// - 返回 [Either<Failure, T>]，调用方显式处理成功/失败
/// - 使用 Domain Entity [ExampleItem]，而非 DTO
/// - 接口定义在 Domain 层，实现在 Data 层
abstract class ExampleRepository {
  Future<Either<Failure, PaginatedData<ExampleItem>>> getList({
    required int pageNum,
    int pageSize = 20,
  });

  Future<Either<Failure, ExampleItem>> getDetail(String id);
}
