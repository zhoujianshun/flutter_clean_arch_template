import 'dart:async';

import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/data/models/todo_model.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/domain/repositories/todo_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_list_provider.g.dart';

@riverpod
class TodoList extends _$TodoList {
  late final TodoRepository _repository = getIt<TodoRepository>();

  @override
  FutureOr<List<TodoModel>> build() async {
    final result = await _repository.getList();
    return result.fold((failure) => throw failure, (items) => items);
  }

  Future<void> add(TodoModel todo) async {
    final result = await _repository.create(todo);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => ref.invalidateSelf(),
    );
  }

  Future<void> remove(String id) async {
    final result = await _repository.delete(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => ref.invalidateSelf(),
    );
  }
}
