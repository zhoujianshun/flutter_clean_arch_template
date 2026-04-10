import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_clean_arch_template/core/logger/formatters/log_formatter.dart';
import 'package:flutter_clean_arch_template/core/logger/log_context.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 控制台日志观察器
/// 负责将日志输出到控制台
class ConsoleObserver extends TalkerObserver {
  ConsoleObserver(this.context);

  final LogContext context;

  @override
  void onLog(TalkerData log) {
    if (!kDebugMode) return;

    // 格式化日志
    final formatted = LogFormatter.format(log, context);

    // 使用 developer.log 输出，避免与 Zone 冲突
    developer.log(
      formatted,
      name: 'AppLogger',
      time: log.time,
      level: _getLogLevel(log),
      error: log.error,
      stackTrace: log.stackTrace,
    );
  }

  @override
  void onError(TalkerError err) {
    if (!kDebugMode) return;

    developer.log(
      err.message ?? 'Error',
      name: 'AppLogger',
      time: err.time,
      level: 1000, // ERROR level
      error: err.error,
      stackTrace: err.stackTrace,
    );
  }

  @override
  void onException(TalkerException err) {
    if (!kDebugMode) return;

    developer.log(
      err.message ?? 'Exception',
      name: 'AppLogger',
      time: err.time,
      level: 1000, // ERROR level
      error: err.exception,
      stackTrace: err.stackTrace,
    );
  }

  /// 获取日志级别（用于 developer.log）
  int _getLogLevel(TalkerData data) {
    if (data is TalkerError || data is TalkerException) {
      return 1000; // ERROR
    }

    if (data is TalkerLog) {
      final title = data.title?.toLowerCase() ?? '';
      if (title.contains('critical') || title.contains('fatal')) {
        return 1200; // CRITICAL
      }
      if (title.contains('error')) {
        return 1000; // ERROR
      }
      if (title.contains('warning') || title.contains('warn')) {
        return 900; // WARNING
      }
      if (title.contains('info')) {
        return 800; // INFO
      }
      if (title.contains('debug')) {
        return 500; // DEBUG
      }
    }

    return 800; // INFO (default)
  }
}
