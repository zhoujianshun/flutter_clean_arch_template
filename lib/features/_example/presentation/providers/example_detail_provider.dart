import 'dart:async';

import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/entities/example_item.dart';
import 'package:flutter_clean_arch_template/features/_example/domain/repositories/example_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'example_detail_provider.g.dart';

@riverpod
Future<ExampleItem> exampleDetail(Ref ref, String id) async {
  final repository = getIt<ExampleRepository>();
  final result = await repository.getDetail(id);
  // 显式 await：确保 throw 的 Failure 作为 Future 错误传播，被 Riverpod 捕获进 AsyncValue.error
  return await result.fold((failure) => throw failure, (item) => item);
}
