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
  return result.fold((failure) => throw failure, (item) => item);
}
