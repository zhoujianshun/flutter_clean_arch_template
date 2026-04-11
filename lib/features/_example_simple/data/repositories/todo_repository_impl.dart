import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/data/datasources/todo_mock_datasource.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/data/datasources/todo_remote_datasource.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/data/models/todo_model.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/domain/repositories/todo_repository.dart';
import 'package:injectable/injectable.dart';

/// 务实型 Repository 实现
///
/// DataSource 已返回 Either<Failure, T>，Repository 直接透传。
/// 无 DTO → Entity 转换步骤 — Model 直接就是业务模型。
///
/// 当 `AppConfig.mockData` 为 true 时，使用 [TodoMockDataSource] 返回本地模拟数据。
@Singleton(as: TodoRepository)
class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._remoteDataSource);

  final TodoRemoteDataSource _remoteDataSource;
  final TodoMockDataSource _mockDataSource = TodoMockDataSource();

  @override
  Future<Either<Failure, List<TodoModel>>> getList() {
    if (AppConfig.mockData) return _mockDataSource.getList();
    return _remoteDataSource.getList();
  }

  @override
  Future<Either<Failure, TodoModel>> getDetail(String id) {
    if (AppConfig.mockData) return _mockDataSource.getDetail(id);
    return _remoteDataSource.getDetail(id);
  }

  @override
  Future<Either<Failure, TodoModel>> create(TodoModel todo) {
    if (AppConfig.mockData) return _mockDataSource.create(todo);
    return _remoteDataSource.create(todo);
  }

  @override
  Future<Either<Failure, void>> delete(String id) {
    if (AppConfig.mockData) return _mockDataSource.delete(id);
    return _remoteDataSource.delete(id);
  }
}
