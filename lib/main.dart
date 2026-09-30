import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/initializers/app_initializer.dart';
import 'package:flutter_clean_arch_template/core/l10n/language_provider.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/router/router_provider.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';
import 'package:flutter_clean_arch_template/core/theme/theme_mode_provider.dart';
import 'package:flutter_clean_arch_template/features/auth/presentation/widgets/auth_navigation_listener.dart';
import 'package:flutter_clean_arch_template/generated/l10n/app_localizations.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runZonedGuarded<void>(
    () {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      _setupErrorHandlers();
      unawaited(_bootstrap(widgetsBinding));
    },
    (error, stackTrace) {
      // AppLogger 初始化前的 release 场景下 Talker 不可用，debugPrint 兜底
      debugPrint('Uncaught zone error: $error');
      AppLogger.fatal('未捕获的异步异常', error: error, stackTrace: stackTrace);
    },
  );
}

/// 应用启动引导：初始化 -> runApp
///
/// 失败时渲染 [_BootstrapErrorApp] 兜底页（含重试），由 [_BootstrapErrorApp]
/// 的重试按钮再次调用。
Future<void> _bootstrap(WidgetsBinding widgetsBinding) async {
  try {
    await AppInitializer.initialize(widgetsBinding);
  } catch (error) {
    // AppInitializer 内部已记录 fatal 日志并移除原生 Splash，这里只需兜底渲染
    runApp(
      _BootstrapErrorApp(
        error: error,
        onRetry: () async {
          // 清掉 GetIt 可能的半初始化状态再重试
          await ServiceLocator.reset();
          await _bootstrap(widgetsBinding);
        },
      ),
    );
    return;
  }

  runApp(
    ProviderScope(
      observers: [
        if (AppLogger.riverpodObserver != null) AppLogger.riverpodObserver!,
      ],
      child: const MyApp(),
    ),
  );
}

/// 安装全局错误钩子
void _setupErrorHandlers() {
  // Flutter 框架错误（build/layout/绘制异常等）
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.fatal(
      'Flutter 框架错误',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Zone 未捕获异步错误（runZonedGuarded 捕不到的平台线程回调等）
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.fatal('平台未捕获异常', error: error, stackTrace: stackTrace);
    return true;
  };

  // Release 下 build 抛异常的占位页（debug 保持默认红屏便于开发）
  ErrorWidget.builder = (details) {
    if (kReleaseMode) {
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Color(0xFF1E1E1E),
          child: Center(
            child: Text(
              '页面出现异常',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );
    }
    return ErrorWidget(details.exception);
  };
}

/// 初始化失败兜底页
///
/// 独立于 DI / l10n / 主题体系（此时它们可能尚未就绪）。
class _BootstrapErrorApp extends StatefulWidget {
  const _BootstrapErrorApp({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  State<_BootstrapErrorApp> createState() => _BootstrapErrorAppState();
}

class _BootstrapErrorAppState extends State<_BootstrapErrorApp> {
  static const int _maxRetries = 3;

  bool _isRetrying = false;
  int _retryCount = 0;

  bool get _exhausted => _retryCount >= _maxRetries;

  Future<void> _retry() async {
    if (_isRetrying || _exhausted) return;

    setState(() => _isRetrying = true);
    _retryCount++;
    try {
      await widget.onRetry();
    } catch (error, stackTrace) {
      AppLogger.error('应用初始化重试失败（$_retryCount/$_maxRetries）',
          error: error, stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Color(0xFFB00020),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _exhausted ? '初始化失败，请重新安装应用' : '应用初始化失败',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (kDebugMode)
                    Text(
                      widget.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (_isRetrying || _exhausted) ? null : _retry,
                    child: _isRetrying
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_exhausted ? '已达最大重试次数' : '重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return ScreenUtilInit(
      designSize: const Size(
        ResponsiveTokens.phoneDesignWidth,
        ResponsiveTokens.phoneDesignHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      fontSizeResolver: (fontSize, instance) {
        // 平板/桌面端（>= 600dp）：不缩放字体，直接使用设计稿 dp 值
        if (instance.screenWidth >= ResponsiveBreakpoints.compact) {
          return fontSize.toDouble();
        }
        // 手机端：宽高混合缩放，避免极端屏幕比例下字体失真
        final scaleW = instance.screenWidth / ResponsiveTokens.phoneDesignWidth;
        final scaleH =
            instance.screenHeight / ResponsiveTokens.phoneDesignHeight;
        final scale = min(scaleW, scaleH) * 0.85 + max(scaleW, scaleH) * 0.15;
        return fontSize * scale;
      },
      builder: (context, child) {
        return AuthNavigationListener(
          child: KeyboardDismissOnTap(
            dismissOnCapturedTaps: true,
            child: MaterialApp.router(
              title: 'Flutter Clean Arch',
              routerConfig: appRouter.config(
                navigatorObservers: () => [
                  if (AppLogger.routeObserver != null) AppLogger.routeObserver!,
                ],
              ),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              builder: EasyLoading.init(),
              debugShowCheckedModeBanner: false,
            ),
          ),
        );
      },
    );
  }
}
