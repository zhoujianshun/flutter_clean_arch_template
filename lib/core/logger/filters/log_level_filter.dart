import 'package:talker_flutter/talker_flutter.dart';

/// 日志级别
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);

  const LogLevel(this.level);
  final int level;

  /// 从字符串解析日志级别
  static LogLevel fromString(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warning':
      case 'warn':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      case 'critical':
      case 'fatal':
        return LogLevel.critical;
      default:
        return LogLevel.info;
    }
  }
}

/// 日志级别过滤器
/// 根据配置的最低日志级别过滤日志
class LogLevelFilter extends TalkerFilter {
  LogLevelFilter({required String minLevel}) : _minLevel = LogLevel.fromString(minLevel);

  final LogLevel _minLevel;

  @override
  bool filter(TalkerData item) {
    final dataLevel = _getLogLevel(item);
    // 返回 true 表示保留该日志，false 表示过滤掉
    return dataLevel.level >= _minLevel.level;
  }

  /// 获取 TalkerData 的日志级别
  LogLevel _getLogLevel(TalkerData data) {
    if (data is TalkerError || data is TalkerException) {
      return LogLevel.error;
    }

    if (data is TalkerLog) {
      final title = data.title?.toLowerCase() ?? '';

      if (title.contains('critical') || title.contains('fatal')) {
        return LogLevel.critical;
      }
      if (title.contains('error')) {
        return LogLevel.error;
      }
      if (title.contains('warning') || title.contains('warn')) {
        return LogLevel.warning;
      }
      if (title.contains('info')) {
        return LogLevel.info;
      }
      if (title.contains('debug')) {
        return LogLevel.debug;
      }
    }

    // 默认为 info 级别
    return LogLevel.info;
  }
}
