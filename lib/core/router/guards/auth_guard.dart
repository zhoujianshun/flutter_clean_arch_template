import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';

@singleton
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authRepository);

  final AuthRepository _authRepository;

  static final Set<String> _redirectingRoutes = <String>{};
  static const int _maxRedirectCount = 3;
  static final Map<String, int> _redirectCounts = <String, int>{};

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final routeName = resolver.route.name;

    if (_isRedirectLoop(routeName)) {
      AppLogger.error('Redirect loop detected: $routeName');
      resolver.redirectUntil(const SplashRoute());
      return;
    }

    try {
      _redirectingRoutes.add(routeName);

      if (_isUnauthRequired(routeName)) {
        _resetRedirectCount(routeName);
        resolver.next();
        return;
      }

      final isAuthenticated = await _authRepository.isUserLoggedIn();

      if (isAuthenticated) {
        _resetRedirectCount(routeName);
        resolver.next();
      } else {
        AppLogger.info('User not logged in, redirecting to login');
        _incrementRedirectCount(routeName);
        resolver.redirectUntil(
          LoginRoute(
            onResult: ({success = false}) {
              resolver.next(success);
            },
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Auth check failed', error: e, stackTrace: stackTrace);
      resolver.redirectUntil(
        LoginRoute(
          onResult: ({success = false}) {
            resolver.next(success);
          },
        ),
      );
    } finally {
      _redirectingRoutes.remove(routeName);
    }
  }

  bool _isRedirectLoop(String routeName) {
    if (_redirectingRoutes.contains(routeName)) {
      return true;
    }
    final count = _redirectCounts[routeName] ?? 0;
    return count >= _maxRedirectCount;
  }

  void _incrementRedirectCount(String routeName) {
    _redirectCounts[routeName] = (_redirectCounts[routeName] ?? 0) + 1;
  }

  void _resetRedirectCount(String routeName) {
    _redirectCounts.remove(routeName);
  }

  static List<String> get unauthRequiredRoutes => [
    SplashRoute.name,
    LoginRoute.name,
    OnboardingRoute.name,
    ConfigManagementRoute.name,
  ];

  bool _isUnauthRequired(String routeName) {
    return unauthRequiredRoutes.contains(routeName);
  }
}
