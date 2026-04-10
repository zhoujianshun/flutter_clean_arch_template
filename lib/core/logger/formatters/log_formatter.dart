import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:flutter_clean_arch_template/core/logger/log_context.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 日志格式化器
class LogFormatter {
  /// 格式化日志为可读文本
  static String format(TalkerData data, LogContext context) {
    final buffer = StringBuffer();

    // 时间戳
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(data.time);
    buffer.write('[$timestamp] ');

    // 日志级别
    final level = _getLogLevel(data);
    buffer.write('[$level] ');

    // 日志消息
    buffer.write(data.message);

    // 添加上下文信息（仅在开发模式或错误日志时）
    if (data is TalkerError || data is TalkerException) {
      buffer.write(' | Context: ${_formatContext(context)}');
    }

    // 错误信息
    if (data.error != null) {
      buffer.write('\n  Error: ${data.error}');
    }

    // 堆栈信息
    if (data.stackTrace != null) {
      buffer.write('\n  StackTrace:\n${_formatStackTrace(data.stackTrace!)}');
    }

    return buffer.toString();
  }

  /// 格式化日志为 JSON
  static String formatJson(TalkerData data, LogContext context) {
    final map = <String, dynamic>{
      'timestamp': data.time.toIso8601String(),
      'level': _getLogLevel(data),
      'message': data.message,
      'context': context.toMap(),
    };

    if (data.error != null) {
      map['error'] = data.error.toString();
    }

    if (data.stackTrace != null) {
      map['stackTrace'] = data.stackTrace.toString();
    }

    if (data is TalkerLog && data.title != null) {
      map['title'] = data.title;
    }

    return jsonEncode(map);
  }

  /// 获取日志级别
  static String _getLogLevel(TalkerData data) {
    if (data is TalkerError) return 'ERROR';
    if (data is TalkerException) return 'EXCEPTION';
    if (data is TalkerLog) {
      // 根据 Talker 内置类型判断
      final title = data.title?.toUpperCase() ?? '';
      if (title.contains('ERROR')) return 'ERROR';
      if (title.contains('WARNING') || title.contains('WARN')) return 'WARNING';
      if (title.contains('INFO')) return 'INFO';
      if (title.contains('DEBUG')) return 'DEBUG';
      if (title.contains('CRITICAL') || title.contains('FATAL')) return 'FATAL';
      return 'INFO';
    }
    return 'INFO';
  }

  /// 格式化上下文信息
  static String _formatContext(LogContext context) {
    final parts = <String>[];

    if (context.userId != null) {
      parts.add('user=${context.userId}');
    }
    if (context.deviceId != null) {
      parts.add('device=${context.deviceId?.substring(0, 8)}...');
    }
    if (context.sessionId != null) {
      parts.add('session=${context.sessionId?.substring(0, 8)}...');
    }
    if (context.appVersion != null) {
      parts.add('v=${context.appVersion}');
    }

    return parts.join(', ');
  }

  /// 格式化堆栈跟踪（简化输出）
  static String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    // 只保留前10行堆栈信息
    final limitedLines = lines.take(10);
    return limitedLines.map((line) => '    $line').join('\n');
  }
}
