import 'package:flutter/foundation.dart';
import 'package:flutter_clean_arch_template/core/logger/filters/log_level_filter.dart'
    as app_filters;
import 'package:flutter_clean_arch_template/core/logger/log_context.dart';
import 'package:flutter_clean_arch_template/core/network/log_sanitizer.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

/// Talker configuration manager
class TalkerConfig {
  static Future<Talker> createTalker({
    required String environment,
    required String logLevel,
    required LogContext context,
  }) async {
    final observers = <TalkerObserver>[];

    // Add your custom observers here per environment, e.g.:
    // if (environment == 'production') {
    //   observers.add(YourRemoteErrorObserver());
    // }

    final filter = app_filters.LogLevelFilter(minLevel: logLevel);

    final talker = TalkerFlutter.init(
      settings: getSettings(environment),
      filter: filter,
      observer: TalkerObserverWrapper(observers),
    );

    return talker;
  }

  static TalkerDioLogger createDioLogger(Talker talker, String environment) {
    final isDebug = kDebugMode || environment == 'development';

    return TalkerDioLogger(
      talker: talker,
      settings: TalkerDioLoggerSettings(
        printRequestHeaders: isDebug,
        printRequestData: isDebug,
        printResponseHeaders: isDebug,
        printResponseData: isDebug,
        // 请求/响应体渲染的统一必经钩子：结构化脱敏后再格式化，
        // 防止 password/token/手机号明文进入日志（含 TalkerScreen 历史与落盘）
        jsonFormatter: _SanitizingJsonFormatter(),
        // 敏感请求头由库遮蔽为 *****（大小写不敏感）
        hiddenHeaders: const {
          'Authorization',
          'Content-Language',
          'ClientId',
          'Cookie',
          'Set-Cookie',
        },
        requestPen: AnsiPen()..blue(),
        responsePen: AnsiPen()..green(),
        errorPen: AnsiPen()..red(),
      ),
    );
  }

  static TalkerRiverpodObserver createRiverpodObserver(
    Talker talker,
    String environment,
  ) {
    final isDebug = kDebugMode || environment == 'development';

    return TalkerRiverpodObserver(
      talker: talker,
      settings: TalkerRiverpodLoggerSettings(
        enabled: isDebug,
        printProviderAdded: isDebug,
        printProviderUpdated: false,
        printProviderDisposed: isDebug,
        printStateFullData: false,
      ),
    );
  }

  static TalkerSettings getSettings(String environment) {
    switch (environment) {
      case 'development':
        return TalkerSettings();
      case 'staging':
        return TalkerSettings(
          maxHistoryItems: 500,
          useConsoleLogs: false,
        );
      case 'production':
        return TalkerSettings(
          maxHistoryItems: 200,
          useConsoleLogs: false,
        );
      default:
        return TalkerSettings(
          maxHistoryItems: 100,
          useConsoleLogs: false,
        );
    }
  }
}

/// Wrapper for multiple Talker observers
class TalkerObserverWrapper extends TalkerObserver {
  TalkerObserverWrapper(this.observers);

  final List<TalkerObserver> observers;

  @override
  void onLog(TalkerData log) {
    for (final observer in observers) {
      observer.onLog(log);
    }
  }

  @override
  void onError(TalkerError err) {
    for (final observer in observers) {
      observer.onError(err);
    }
  }

  @override
  void onException(TalkerException err) {
    for (final observer in observers) {
      observer.onException(err);
    }
  }
}

/// 脱敏 JSON 格式化器
///
/// DioRequestLog/DioResponseLog/DioErrorLog 渲染 body 时统一经过
/// jsonFormatter.format，在此对结构化数据先做递归脱敏（比正则更可靠，
/// 能正确处理嵌套 Map/List 与非 JSON 值），再交给默认格式化器。
class _SanitizingJsonFormatter extends TalkerJsonFormatter {
  @override
  String format(dynamic data) {
    if (data is Map || data is List) {
      return super.format(LogSanitizer.sanitizeBody(data));
    }
    return super.format(data);
  }
}
