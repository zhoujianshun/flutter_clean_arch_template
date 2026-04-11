import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/data/models/todo_model.dart';

/// 务实型 Repository 接口
///
/// 与标准型的区别：直接使用 Data 层的 [TodoModel]，无需独立 Entity。
/// Domain 层可直接引用 Data 层 Model（务实做法，减少样板代码）。
abstract class TodoRepository {
  Future<Either<Failure, List<TodoModel>>> getList();
  Future<Either<Failure, TodoModel>> getDetail(String id);
  Future<Either<Failure, TodoModel>> create(TodoModel todo);
  Future<Either<Failure, void>> delete(String id);
}
