import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';

abstract class ExampleRepository {
  Future<Either<Failure, PaginatedData<ExampleItem>>> getList({
    required int pageNum,
    int pageSize = 20,
  });
  Future<Either<Failure, ExampleItem>> getDetail(String id);
}
