import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/core/router/guards/auth_guard.dart';
import 'package:flutter_clean_arch_template/core/router/guards/debouncer_guard.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

/// AppRouter Provider
/// 提供 AppRouter 实例，包含认证守卫、防抖动守卫和导航观察者
@Riverpod(keepAlive: true)
Raw<AppRouter> appRouter(Ref ref) {
  return AppRouter(
    authGuard: getIt<AuthGuard>(),
    debouncerGuard: getIt<DebouncerGuard>(),
  );
}
