import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_example_simple/presentation/providers/todo_list_provider.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTodos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos (Simple)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(todoListProvider),
          ),
        ],
      ),
      body: asyncTodos.when(
        data: (todos) {
          if (todos.isEmpty) {
            return const Center(child: Text('No todos yet'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    todo.isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: todo.isCompleted ? Colors.green : null,
                  ),
                  title: Text(todo.title),
                  subtitle: todo.description != null
                      ? Text(
                          todo.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (error, stack) => AppErrorWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(todoListProvider),
        ),
      ),
    );
  }
}
