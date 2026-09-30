import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/constants/app_constants.dart';
import 'package:flutter_clean_arch_template/core/constants/auth_mode.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/app_router.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _initialDelayCompleted = false;
  bool _isRetrying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (_isRetrying) {
      return;
    }

    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });

    if (!_initialDelayCompleted) {
      await Future<void>.delayed(AppConstants.splashDuration);
      _initialDelayCompleted = true;
      FlutterNativeSplash.remove();
    }

    if (!mounted) return;

    try {
      final authRepo = getIt<AuthRepository>();
      final isLoggedIn = await authRepo.isUserLoggedIn();
      if (!mounted) return;

      final authMode = AppConfig.authMode;

      if (isLoggedIn) {
        unawaited(context.router.replaceAll([const AppShellRoute()]));
      } else if (authMode == AuthMode.optional) {
        // Guest-friendly mode: go to home without login
        unawaited(context.router.replaceAll([const AppShellRoute()]));
      } else {
        // Required mode: must login first
        unawaited(context.router.replaceAll([LoginRoute()]));
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Splash initialization error',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _errorMessage = '无法读取登录状态，请检查设备状态后重试';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Flutter Clean Arch',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Template',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isRetrying ? null : _initialize,
                child: _isRetrying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
