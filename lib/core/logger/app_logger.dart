import 'package:flutter/foundation.dart';
import 'package:flutter_clean_arch_template/core/logger/filters/sensitive_filter.dart';
import 'package:flutter_clean_arch_template/core/logger/log_context.dart';
import 'package:flutter_clean_arch_template/core/logger/performance_monitor.dart';
import 'package:flutter_clean_arch_template/core/logger/talker_config.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

/// 应用日志系统
/// 基于 Talker 的统一日志管理
class AppLogger {
  static late Talker _talker;
  static late LogContext _context;
  static TalkerDioLogger? _dioLogger;
  static TalkerRiverpodObserver? _riverpodObserver;
  static TalkerRouteObserver? _routeObserver;
  static bool _initialized = false;

  // 早期日志缓冲区（用于在完全初始化前缓存日志）
  static final List<Map<String, dynamic>> _earlyLogBuffer = [];
  static const int _maxEarlyLogs = 100; // 限制缓冲区大小

  /// 初始化日志系统
  /// [environment] 环境类型（development/staging/production）
  /// [logLevel] 日志级别（debug/info/warning/error）
  static Future<void> initialize({
    String? environment,
    String? logLevel,
  }) async {
    if (_initialized) return;

    try {
      // 使用提供的参数或默认值
      final env = environment ?? (kDebugMode ? 'development' : 'production');
      final level = logLevel ?? (kDebugMode ? 'debug' : 'error');

      // 创建日志上下文
      _context = await LogContext.create();

      // 创建 Talker 实例
      _talker = await TalkerConfig.createTalker(
        environment: env,
        logLevel: level,
        context: _context,
      );

      // 创建 Dio Logger
      _dioLogger = TalkerConfig.createDioLogger(_talker, env);

      // 创建 Riverpod Observer
      _riverpodObserver = TalkerConfig.createRiverpodObserver(_talker, env);

      // 创建 Route Observer
      _routeObserver = TalkerRouteObserver(_talker);

      _initialized = true;

      // 转储早期日志到 Talker
      _flushEarlyLogs();
    } catch (e) {
      // 初始化失败时使用默认配置
      _context = LogContext();
      _talker = TalkerFlutter.init();
      _initialized = true;
      _flushEarlyLogs();
    }
  }

  /// 处理早期日志（在完全初始化前）
  static void _handleEarlyLog(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 在 debug 模式下输出到控制台并缓存
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp][$level] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }

      // 缓存日志（限制数量）
      if (_earlyLogBuffer.length < _maxEarlyLogs) {
        _earlyLogBuffer.add({
          'level': level,
          'message': message,
          'error': error,
          'stackTrace': stackTrace,
          'timestamp': DateTime.now(),
        });
      }
    }
  }

  /// 转储早期日志到 Talker
  static void _flushEarlyLogs() {
    if (_earlyLogBuffer.isEmpty) return;

    try {
      for (final log in _earlyLogBuffer) {
        final level = log['level'] as String;
        final message = log['message'] as String;
        final error = log['error'] as Object?;
        final stackTrace = log['stackTrace'] as StackTrace?;

        /// 早期日志的时间戳，格式化成9:30:58 352ms的形式
        final timestamp = log['timestamp'] as DateTime;
        final formattedTimestamp =
            '${timestamp.hour}:${timestamp.minute}:${timestamp.second} ${timestamp.millisecond}ms';

        // 添加标记表示这是早期日志
        final earlyMessage = '[早期日志] $formattedTimestamp $message';

        switch (level) {
          case 'DEBUG':
            if (error != null || stackTrace != null) {
              _talker.logCustom(
                TalkerLog(earlyMessage, title: 'DEBUG', stackTrace: stackTrace),
              );
            } else {
              _talker.debug(earlyMessage);
            }
          case 'INFO':
            if (error != null || stackTrace != null) {
              _talker.logCustom(
                TalkerLog(earlyMessage, title: 'INFO', stackTrace: stackTrace),
              );
            } else {
              _talker.info(earlyMessage);
            }
          case 'WARNING':
            if (error != null || stackTrace != null) {
              _talker.logCustom(
                TalkerLog(earlyMessage, title: 'WARNING', stackTrace: stackTrace),
              );
            } else {
              _talker.warning(earlyMessage);
            }
          case 'ERROR':
            if (error != null) {
              _talker.handle(error, stackTrace, earlyMessage);
            } else {
              _talker.error(earlyMessage);
            }
          case 'FATAL':
            if (error != null) {
              _talker.handle(error, stackTrace, earlyMessage);
            } else {
              _talker.critical(earlyMessage);
            }
        }
      }

      // 清空缓冲区
      _earlyLogBuffer.clear();
    } catch (e) {
      // 转储失败也不应该影响应用运行
      debugPrint('转储早期日志失败: $e');
    }
  }

  /// 确保已初始化
  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('AppLogger 未初始化，请先调用 AppLogger.initialize()');
    }
  }

  /// Debug 级别日志
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      _handleEarlyLog('DEBUG', message, error: error, stackTrace: stackTrace);
      return;
    }

    final filteredMessage = SensitiveFilter.filterSensitiveData(message);

    if (error != null || stackTrace != null) {
      _talker.logCustom(
        TalkerLog(
          filteredMessage,
          title: 'DEBUG',
          stackTrace: stackTrace,
        ),
      );
    } else {
      _talker.debug(filteredMessage);
    }
  }

  /// Info 级别日志
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      _handleEarlyLog('INFO', message, error: error, stackTrace: stackTrace);
      return;
    }

    final filteredMessage = SensitiveFilter.filterSensitiveData(message);

    if (error != null || stackTrace != null) {
      _talker.logCustom(
        TalkerLog(
          filteredMessage,
          title: 'INFO',
          stackTrace: stackTrace,
        ),
      );
    } else {
      _talker.info(filteredMessage);
    }
  }

  /// Warning 级别日志
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      _handleEarlyLog('WARNING', message, error: error, stackTrace: stackTrace);
      return;
    }

    final filteredMessage = SensitiveFilter.filterSensitiveData(message);

    if (error != null || stackTrace != null) {
      _talker.logCustom(
        TalkerLog(
          filteredMessage,
          title: 'WARNING',
          stackTrace: stackTrace,
        ),
      );
    } else {
      _talker.warning(filteredMessage);
    }
  }

  /// Error 级别日志
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      _handleEarlyLog('ERROR', message, error: error, stackTrace: stackTrace);
      return;
    }

    final filteredMessage = SensitiveFilter.filterSensitiveData(message);

    if (error != null) {
      // 如果有error对象，使用handle方法
      _talker.handle(error, stackTrace, filteredMessage);
    } else {
      _talker.error(filteredMessage);
    }
  }

  /// Fatal/Critical 级别日志
  static void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      _handleEarlyLog('FATAL', message, error: error, stackTrace: stackTrace);
      return;
    }

    final filteredMessage = SensitiveFilter.filterSensitiveData(message);

    if (error != null) {
      // 如果有error对象，使用handle方法
      _talker.handle(error, stackTrace, filteredMessage);
    } else {
      _talker.critical(filteredMessage);
    }
  }

  /// Debug 级别日志（简写）
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    debug(message, error: error, stackTrace: stackTrace);
  }

  /// Info 级别日志（简写）
  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    info(message, error: error, stackTrace: stackTrace);
  }

  /// Warning 级别日志（简写）
  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    warning(message, error: error, stackTrace: stackTrace);
  }

  /// Error 级别日志（简写）
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.error(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal 级别日志（简写）
  static void f(String message, {Object? error, StackTrace? stackTrace}) {
    fatal(message, error: error, stackTrace: stackTrace);
  }

  /// HTTP 日志
  static void http(String message, {Map<String, dynamic>? data}) {
    if (!_initialized) return;

    // 过滤敏感信息
    final filteredMessage = SensitiveFilter.filterSensitiveData(message);
    final filteredData = data != null ? SensitiveFilter.maskSensitiveMap(data) : null;

    _talker.logCustom(
      HttpTalkerLog(filteredMessage, data: filteredData),
    );
  }

  /// 异常日志
  static void exception(
    Object exception,
    StackTrace stackTrace, {
    String? message,
    Map<String, dynamic>? context,
  }) {
    if (!_initialized) return;

    final logMessage = message != null ? '$message: $exception' : exception.toString();
    final filteredMessage = SensitiveFilter.filterSensitiveData(logMessage);

    _talker.handle(exception, stackTrace, filteredMessage);
  }

  /// 获取 Talker 实例（用于高级用法，如 TalkerScreen）
  static Talker get talker {
    _ensureInitialized();
    return _talker;
  }

  /// 获取 TalkerDioLogger 实例（用于 ApiClient）
  static TalkerDioLogger? get dioLogger {
    return _dioLogger;
  }

  /// 获取 TalkerRiverpodObserver 实例（用于 ProviderScope）
  static TalkerRiverpodObserver? get riverpodObserver {
    return _riverpodObserver;
  }

  /// 获取 TalkerRouteObserver 实例（用于 auto_route navigatorObservers）
  static TalkerRouteObserver? get routeObserver {
    return _routeObserver;
  }

  /// 更新日志上下文
  static void updateContext({
    String? userId,
    Map<String, dynamic>? custom,
  }) {
    if (!_initialized) return;

    _context = _context.copyWith(
      userId: userId,
      custom: custom,
    );
  }

  /// 获取当前日志上下文
  static LogContext get context {
    _ensureInitialized();
    return _context;
  }

  /// 清空日志历史
  static void clear() {
    if (!_initialized) return;
    _talker.cleanHistory();
  }

  /// 获取日志历史
  static List<TalkerData> get history {
    if (!_initialized) return [];
    return _talker.history;
  }

  // ==================== 性能监控方法 ====================

  /// 监控同步操作的执行时间
  /// [name] 操作名称
  /// [operation] 要执行的操作
  /// [logResult] 是否记录操作结果（默认 false）
  static T measure<T>(
    String name,
    T Function() operation, {
    bool logResult = false,
  }) {
    return PerformanceMonitor.measure(
      name,
      operation,
      logResult: logResult,
    );
  }

  /// 监控异步操作的执行时间
  /// [name] 操作名称
  /// [operation] 要执行的异步操作
  /// [logResult] 是否记录操作结果（默认 false）
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation, {
    bool logResult = false,
  }) {
    return PerformanceMonitor.measureAsync(
      name,
      operation,
      logResult: logResult,
    );
  }

  /// 开始性能计时
  /// [name] 操作名称
  /// [autoLog] 是否自动记录日志（默认 true）
  static PerformanceTimer startTimer(String name, {bool autoLog = true}) {
    return PerformanceMonitor.start(name, autoLog: autoLog);
  }

  /// 获取性能统计
  /// [name] 操作名称
  static PerformanceStats? getPerformanceStats(String name) {
    return PerformanceMonitor.getStats(name);
  }

  /// 获取所有性能统计
  static Map<String, PerformanceStats> getAllPerformanceStats() {
    return PerformanceMonitor.getAllStats();
  }

  /// 打印性能统计报告
  static void printPerformanceReport() {
    PerformanceMonitor.printReport();
  }

  /// 清除性能记录
  /// [name] 操作名称，为 null 时清除所有记录
  static void clearPerformanceRecords([String? name]) {
    PerformanceMonitor.clearRecords(name);
  }
}

/// 自定义 HTTP 日志类型
class HttpTalkerLog extends TalkerLog {
  HttpTalkerLog(
    String super.message, {
    this.data,
  });

  final Map<String, dynamic>? data;

  @override
  String get key => 'http';

  @override
  String get title => 'HTTP';

  @override
  AnsiPen get pen => AnsiPen()..cyan();
}
