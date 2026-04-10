import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';

/// 性能监控器
/// 用于监控和记录各种操作的执行时间
///
/// 使用方式：
/// ```dart
/// // 方式1: 使用 measure 方法
/// final result = await PerformanceMonitor.measure(
///   'fetchUserData',
///   () => fetchUserData(),
/// );
///
/// // 方式2: 使用 PerformanceTimer
/// final timer = PerformanceMonitor.start('complexOperation');
/// // ... 执行操作
/// timer.stop(); // 自动记录耗时
///
/// // 方式3: 使用 measureAsync
/// await PerformanceMonitor.measureAsync(
///   'loadData',
///   () async => await loadData(),
/// );
/// ```
class PerformanceMonitor {
  PerformanceMonitor._();

  /// 性能记录缓存
  static final Map<String, List<PerformanceRecord>> _records = {};

  /// 最大记录数量（每个操作）
  static const int _maxRecordsPerOperation = 100;

  /// 慢操作阈值（毫秒）
  static const int slowOperationThreshold = 1000; // 1秒

  /// 监控同步操作
  /// [name] 操作名称
  /// [operation] 要执行的操作
  /// [logResult] 是否记录操作结果（默认 false）
  static T measure<T>(
    String name,
    T Function() operation, {
    bool logResult = false,
  }) {
    final stopwatch = Stopwatch()..start();
    Object? resultForLog;
    Object? error;
    StackTrace? stackTrace;

    try {
      final result = operation();
      resultForLog = result;
      return result;
    } catch (e, st) {
      error = e;
      stackTrace = st;
      rethrow; // 总是抛出错误
    } finally {
      stopwatch.stop();
      _recordPerformance(
        name: name,
        duration: stopwatch.elapsedMilliseconds,
        success: error == null,
        error: error,
        stackTrace: stackTrace,
        result: logResult ? resultForLog : null,
      );
    }
  }

  /// 监控异步操作
  /// [name] 操作名称
  /// [operation] 要执行的异步操作
  /// [logResult] 是否记录操作结果（默认 false）
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation, {
    bool logResult = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    Object? resultForLog;
    Object? error;
    StackTrace? stackTrace;

    try {
      final result = await operation();
      resultForLog = result;
      return result;
    } catch (e, st) {
      error = e;
      stackTrace = st;
      rethrow; // 总是抛出错误
    } finally {
      stopwatch.stop();
      _recordPerformance(
        name: name,
        duration: stopwatch.elapsedMilliseconds,
        success: error == null,
        error: error,
        stackTrace: stackTrace,
        result: logResult ? resultForLog : null,
      );
    }
  }

  /// 开始计时
  /// [name] 操作名称
  /// [autoLog] 是否自动记录日志（默认 true）
  static PerformanceTimer start(String name, {bool autoLog = true}) {
    return PerformanceTimer._(name, autoLog: autoLog);
  }

  /// 记录性能数据
  static void _recordPerformance({
    required String name,
    required int duration,
    required bool success,
    Object? error,
    StackTrace? stackTrace,
    Object? result,
  }) {
    final record = PerformanceRecord(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
      success: success,
      error: error,
      stackTrace: stackTrace,
      result: result,
    );

    // 添加到缓存
    _records.putIfAbsent(name, () => []).add(record);

    // 限制缓存大小
    if (_records[name]!.length > _maxRecordsPerOperation) {
      _records[name]!.removeAt(0);
    }

    // 记录日志
    _logPerformance(record);
  }

  /// 记录性能日志
  static void _logPerformance(PerformanceRecord record) {
    final isSlow = record.duration >= slowOperationThreshold;
    final emoji = record.success ? (isSlow ? '🐌' : '⚡') : '❌';

    final message = '$emoji [${record.name}] ${record.duration}ms';

    if (!record.success) {
      // 失败的操作
      AppLogger.error(
        message,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    } else if (isSlow) {
      // 慢操作
      AppLogger.warning(message);
    } else if (kDebugMode) {
      // 开发环境记录所有性能数据
      AppLogger.debug(message);
    }
  }

  /// 获取操作的性能统计
  /// [name] 操作名称
  static PerformanceStats? getStats(String name) {
    final records = _records[name];
    if (records == null || records.isEmpty) {
      return null;
    }

    final durations = records.map((r) => r.duration).toList();
    final successCount = records.where((r) => r.success).length;

    return PerformanceStats(
      name: name,
      totalCalls: records.length,
      successCount: successCount,
      failureCount: records.length - successCount,
      minDuration: durations.reduce((a, b) => a < b ? a : b),
      maxDuration: durations.reduce((a, b) => a > b ? a : b),
      avgDuration: durations.reduce((a, b) => a + b) ~/ durations.length,
      slowOperations: records.where((r) => r.duration >= slowOperationThreshold).length,
    );
  }

  /// 获取所有操作的性能统计
  static Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};
    for (final name in _records.keys) {
      final stat = getStats(name);
      if (stat != null) {
        stats[name] = stat;
      }
    }
    return stats;
  }

  /// 清除性能记录
  /// [name] 操作名称，为 null 时清除所有记录
  static void clearRecords([String? name]) {
    if (name != null) {
      _records.remove(name);
      AppLogger.debug('🧹 清除性能记录: $name');
    } else {
      _records.clear();
      AppLogger.debug('🧹 清除所有性能记录');
    }
  }

  /// 打印性能统计报告
  static void printReport() {
    if (_records.isEmpty) {
      AppLogger.info('📊 性能统计: 暂无数据');
      return;
    }

    final stats = getAllStats();
    final sortedStats = stats.entries.toList()..sort((a, b) => b.value.avgDuration.compareTo(a.value.avgDuration));

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('=' * 80)
      ..writeln('📊 性能统计报告')
      ..writeln('=' * 80)
      ..writeln('生成时间: ${DateTime.now()}')
      ..writeln('总操作数: ${stats.length}')
      ..writeln();

    for (final entry in sortedStats) {
      final stat = entry.value;
      buffer
        ..writeln('📈 ${stat.name}')
        ..writeln('  调用次数: ${stat.totalCalls}')
        ..writeln('  成功率: ${(stat.successCount / stat.totalCalls * 100).toStringAsFixed(1)}%')
        ..writeln('  平均耗时: ${stat.avgDuration}ms')
        ..writeln('  最小耗时: ${stat.minDuration}ms')
        ..writeln('  最大耗时: ${stat.maxDuration}ms');
      if (stat.slowOperations > 0) {
        buffer.writeln('  🐌 慢操作: ${stat.slowOperations} 次');
      }
      buffer.writeln();
    }

    buffer.writeln('=' * 80);
    AppLogger.info(buffer.toString());
  }

  /// 设置慢操作阈值（毫秒）
  static int get slowThreshold => slowOperationThreshold;
}

/// 性能计时器
class PerformanceTimer {
  PerformanceTimer._(this.name, {this.autoLog = true}) {
    _stopwatch.start();
    if (kDebugMode) {
      AppLogger.debug('⏱️ 开始计时: $name');
    }
  }

  final String name;
  final bool autoLog;
  final Stopwatch _stopwatch = Stopwatch();
  bool _stopped = false;

  /// 获取当前耗时（毫秒）
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  /// 获取当前耗时（秒）
  double get elapsedSeconds => _stopwatch.elapsedMilliseconds / 1000;

  /// 停止计时并记录
  int stop({Object? result, bool? logResult}) {
    if (_stopped) {
      AppLogger.warning('⚠️ 计时器已停止: $name');
      return _stopwatch.elapsedMilliseconds;
    }

    _stopwatch.stop();
    _stopped = true;

    final duration = _stopwatch.elapsedMilliseconds;

    if (autoLog) {
      PerformanceMonitor._recordPerformance(
        name: name,
        duration: duration,
        success: true,
        result: (logResult ?? false) ? result : null,
      );
    }

    return duration;
  }

  /// 记录检查点
  /// [checkpointName] 检查点名称
  void checkpoint(String checkpointName) {
    if (_stopped) {
      AppLogger.warning('⚠️ 计时器已停止: $name');
      return;
    }

    final duration = _stopwatch.elapsedMilliseconds;
    AppLogger.debug('⏱️ [$name] 检查点 [$checkpointName]: ${duration}ms');
  }

  /// 重置计时器
  void reset() {
    _stopwatch
      ..reset()
      ..start();
    _stopped = false;
  }
}

/// 性能记录
class PerformanceRecord {
  const PerformanceRecord({
    required this.name,
    required this.duration,
    required this.timestamp,
    required this.success,
    this.error,
    this.stackTrace,
    this.result,
  });

  final String name;
  final int duration;
  final DateTime timestamp;
  final bool success;
  final Object? error;
  final StackTrace? stackTrace;
  final Object? result;
}

/// 性能统计
class PerformanceStats {
  const PerformanceStats({
    required this.name,
    required this.totalCalls,
    required this.successCount,
    required this.failureCount,
    required this.minDuration,
    required this.maxDuration,
    required this.avgDuration,
    required this.slowOperations,
  });

  final String name;
  final int totalCalls;
  final int successCount;
  final int failureCount;
  final int minDuration;
  final int maxDuration;
  final int avgDuration;
  final int slowOperations;

  /// 成功率
  double get successRate => successCount / totalCalls;

  @override
  String toString() {
    return 'PerformanceStats{'
        'name: $name, '
        'calls: $totalCalls, '
        'successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
        'avgDuration: ${avgDuration}ms, '
        'minDuration: ${minDuration}ms, '
        'maxDuration: ${maxDuration}ms, '
        'slowOps: $slowOperations'
        '}';
  }
}
