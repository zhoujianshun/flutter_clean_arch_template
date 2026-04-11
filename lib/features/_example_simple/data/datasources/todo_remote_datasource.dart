import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/network/base_api.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/data/models/todo_model.dart';
import 'package:injectable/injectable.dart';

/// 务实型数据源：继承 BaseAPI 获得统一错误处理
@singleton
class TodoRemoteDataSource extends BaseAPI {
  TodoRemoteDataSource(super.apiClient);

  static const _basePath = '/todos';

  Future<Either<Failure, List<TodoModel>>> getList() async {
    return handleApiListCall(
      apiClient.get(_basePath),
      TodoModel.fromJson,
      logTag: 'TodoRemoteDataSource.getList',
    );
  }

  Future<Either<Failure, TodoModel>> getDetail(String id) async {
    return handleApiCall(
      apiClient.get('$_basePath/$id'),
      TodoModel.fromJson,
      logTag: 'TodoRemoteDataSource.getDetail',
    );
  }

  Future<Either<Failure, TodoModel>> create(TodoModel todo) async {
    return handleApiCall(
      apiClient.post(_basePath, data: todo.toJson()),
      TodoModel.fromJson,
      logTag: 'TodoRemoteDataSource.create',
    );
  }

  Future<Either<Failure, void>> delete(String id) async {
    return handleApiVoidCall(
      apiClient.delete('$_basePath/$id'),
      logTag: 'TodoRemoteDataSource.delete',
    );
  }
}
