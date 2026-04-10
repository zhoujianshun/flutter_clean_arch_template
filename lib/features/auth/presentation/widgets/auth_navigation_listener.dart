import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/core/router/router_provider.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/providers/models/auth_state.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNavigationListener extends ConsumerStatefulWidget {
  const AuthNavigationListener({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AuthNavigationListener> createState() => _AuthNavigationListenerState();
}

class _AuthNavigationListenerState extends ConsumerState<AuthNavigationListener> {
  bool _isNavigatingToLogin = false;
  Timer? _resetNavigationTimer;
  DateTime? _lastProcessedChangeTime;

  @override
  void dispose() {
    _resetNavigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, _handleAuthStateChange);
    return widget.child;
  }

  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    if (next.changeReason == null) return;
    if (next.changeTime != null && next.changeTime == _lastProcessedChangeTime) return;
    _lastProcessedChangeTime = next.changeTime;

    switch (next.changeReason!) {
      case AuthStateChangeReason.loginSuccess:
        break;
      case AuthStateChangeReason.logoutCompleted:
        _navigateToLogin(message: next.changeContext);
      case AuthStateChangeReason.tokenExpired:
      case AuthStateChangeReason.authenticationFailed:
        _navigateToLogin();
      case AuthStateChangeReason.loginFailed:
      case AuthStateChangeReason.appInitializedNoToken:
      case AuthStateChangeReason.appInitializedWithToken:
      case AuthStateChangeReason.userInfoLoaded:
      case AuthStateChangeReason.userInfoLoadFailed:
      case AuthStateChangeReason.dataCleared:
      case AuthStateChangeReason.userInitiated:
        break;
    }
  }

  void _navigateToLogin({String? message}) {
    if (_isNavigatingToLogin) return;
    _isNavigatingToLogin = true;
    _resetNavigationTimer?.cancel();
    _resetNavigationTimer = Timer(const Duration(seconds: 2), () {
      _isNavigatingToLogin = false;
    });

    try {
      final router = ref.read(appRouterProvider);
      if (router.current.name == LoginRoute.name) {
        if (message != null) unawaited(MyEasyPopMessage.showInfo(message));
        return;
      }
      if (message != null) unawaited(MyEasyPopMessage.showInfo(message));
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (router.current.name != LoginRoute.name) {
          unawaited(router.replaceAll([LoginRoute()]));
        }
      });
    } catch (e) {
      AppLogger.e('AuthNavigationListener: Error navigating to login', error: e);
    }
  }
}
