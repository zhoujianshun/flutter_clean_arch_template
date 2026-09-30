import 'package:auto_route/auto_route.dart';
import 'package:flutter_clean_arch_template/core/constants/app_constants.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/core/router/guards/auth_guard.dart';
import 'package:flutter_clean_arch_template/core/router/guards/debouncer_guard.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AppRouter demo configuration', () {
    test('should keep shell child route names unique', () {
      final router = AppRouter(
        authGuard: AuthGuard(_MockAuthRepository()),
        debouncerGuard: DebouncerGuard(),
      );
      final shellRoute = router.routes.firstWhere(
        (route) => route.name == AppShellRoute.name,
      );
      final children = shellRoute.children ?? const <AutoRoute>[];
      final routeNames = children.map((route) => route.name).toList();

      expect(routeNames.toSet(), hasLength(routeNames.length));
      expect(
        routeNames,
        AppConstants.includeDemos
            ? [ExampleListRoute.name, ProfileRoute.name]
            : [ProfileRoute.name],
      );
    });
  });
}
