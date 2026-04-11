import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/data/models/todo_model.dart';

/// Todo 功能的 Mock 数据源
///
/// 提供本地模拟数据，支持 CRUD 操作。
/// 通过 `AppConfig.mockData` 控制是否启用。
class TodoMockDataSource {
  final List<TodoModel> _mockTodos = [
    TodoModel(
      id: '1',
      title: '学习 Flutter 整洁架构',
      description: '了解 Feature-First + DDD + Clean Architecture 的分层设计',
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    TodoModel(
      id: '2',
      title: '配置 Riverpod 状态管理',
      description: '使用 @riverpod 注解创建 Provider，结合 GetIt 依赖注入',
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TodoModel(
      id: '3',
      title: '实现网络请求层',
      description: '基于 Dio 封装 ApiClient，统一错误处理返回 Either<Failure, T>',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TodoModel(
      id: '4',
      title: '编写 Freezed 数据模型',
      description: '使用 @freezed 生成不可变数据类和 JSON 序列化代码',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TodoModel(
      id: '5',
      title: '添加路由导航',
      description: '使用 AutoRoute 配置类型安全的页面路由和路由守卫',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  int _nextId = 6;

  Future<Either<Failure, List<TodoModel>>> getList() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    AppLogger.debug('[MOCK] TodoMockDataSource.getList: ${_mockTodos.length} items');
    return Right(List.unmodifiable(_mockTodos));
  }

  Future<Either<Failure, TodoModel>> getDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    AppLogger.debug('[MOCK] TodoMockDataSource.getDetail: id=$id');

    try {
      final item = _mockTodos.firstWhere((e) => e.id == id);
      return Right(item);
    } catch (_) {
      return const Left(Failure.unknown(message: '[MOCK] Todo not found'));
    }
  }

  Future<Either<Failure, TodoModel>> create(TodoModel todo) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final newTodo = todo.copyWith(
      id: '${_nextId++}',
      createdAt: DateTime.now(),
    );
    _mockTodos.add(newTodo);

    AppLogger.debug('[MOCK] TodoMockDataSource.create: ${newTodo.title}');
    return Right(newTodo);
  }

  Future<Either<Failure, void>> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final index = _mockTodos.indexWhere((e) => e.id == id);
    if (index == -1) {
      return const Left(Failure.unknown(message: '[MOCK] Todo not found'));
    }

    _mockTodos.removeAt(index);
    AppLogger.debug('[MOCK] TodoMockDataSource.delete: id=$id');
    return const Right(null);
  }
}
