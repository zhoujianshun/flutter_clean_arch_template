import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/repositories/example_repository.dart';
import 'package:flutter_clean_arch_template/shared/models/api/api_response.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: ExampleRepository)
class ExampleRepositoryImpl implements ExampleRepository {
  static final List<ExampleItem> _mockItems = List.generate(
    50,
    (i) => ExampleItem(
      id: '${i + 1}',
      title: 'Example Item ${i + 1}',
      description: 'This is the description for item ${i + 1}. It demonstrates the Clean Architecture pattern.',
      isCompleted: i % 3 == 0,
      createdAt: DateTime.now().subtract(Duration(hours: i * 2)),
    ),
  );

  @override
  Future<Either<Failure, PaginatedData<ExampleItem>>> getList({
    required int pageNum,
    int pageSize = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final start = (pageNum - 1) * pageSize;
    final end = start + pageSize;
    final items = _mockItems.sublist(
      start.clamp(0, _mockItems.length),
      end.clamp(0, _mockItems.length),
    );

    return Right(
      PaginatedData<ExampleItem>(
        rows: items,
        total: _mockItems.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ExampleItem>> getDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final item = _mockItems.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('Item not found'),
    );

    return Right(item);
  }
}
