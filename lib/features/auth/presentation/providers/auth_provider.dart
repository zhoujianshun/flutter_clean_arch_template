import 'dart:async';

import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/auth_config.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error.dart';
import 'package:flutter_clean_arch_template/core/network/errors/network_error_notifier.dart';
import 'package:flutter_clean_arch_template/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/phone_login_request.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/providers/models/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late final AuthRepository _authRepository = getIt<AuthRepository>();

  @override
  AuthState build() {
    _listenToNetworkErrors();
    _registerAuthConfig();
    unawaited(_checkInitialAuthState());
    return const AuthState();
  }

  void _registerAuthConfig() {
    if (getIt.isRegistered<AuthConfig>()) {
      // ignore: discarded_futures — GetIt.unregister may return FutureOr; fire-and-forget at startup
      getIt.unregister<AuthConfig>();
    }
    getIt.registerSingleton<AuthConfig>(
      const AuthConfig(
        publicPaths: [UserApiEndpoints.login, UserApiEndpoints.smsCode],
      ),
    );
  }

  void _listenToNetworkErrors() {
    final errorNotifier = getIt<NetworkErrorNotifier>();
    errorNotifier.authErrorStream.listen(_handleAuthError);
  }

  void _handleAuthError(NetworkAuthError error) {
    AppLogger.warning('Auth error received: $error');
    final message = switch (error) {
      TokenExpiredError(:final message) => message,
      AuthenticationFailedError(:final message) => message,
    };
    unawaited(_performLogout(LogoutReason.authenticationFailed, message));
  }

  Future<void> _checkInitialAuthState() async {
    final isLoggedIn = await _authRepository.isUserLoggedIn();
    state = state.copyWith(
      isAuthenticated: isLoggedIn,
      changeReason: isLoggedIn
          ? AuthStateChangeReason.appInitializedWithToken
          : AuthStateChangeReason.appInitializedNoToken,
      changeTime: DateTime.now(),
    );
  }

  Future<void> phoneLogin({
    required String phonenumber,
    required String smsCode,
  }) async {
    final request = PhoneLoginRequest(
      clientId: AppConfig.clientId,
      grantType: 'sms',
      phonenumber: phonenumber.trim(),
      smsCode: smsCode.trim(),
    );

    final result = await _authRepository.phoneLogin(request);
    result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: failure.message,
          changeReason: AuthStateChangeReason.loginFailed,
          changeTime: DateTime.now(),
        );
      },
      (authInfo) {
        state = state.copyWith(
          isAuthenticated: true,
          accessToken: authInfo.accessToken,
          errorMessage: null,
          changeReason: AuthStateChangeReason.loginSuccess,
          changeTime: DateTime.now(),
        );
      },
    );
  }

  Future<void> logout() async {
    await _performLogout(LogoutReason.userInitiated, null);
  }

  Future<void> _performLogout(LogoutReason reason, String? message) async {
    await _authRepository.logout();
    state = AuthState(
      changeReason: AuthStateChangeReason.logoutCompleted,
      changeTime: DateTime.now(),
      logoutReason: reason,
      changeContext: message,
    );
  }
}
