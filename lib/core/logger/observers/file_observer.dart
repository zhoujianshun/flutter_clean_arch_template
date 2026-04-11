import 'dart:async';
import 'dart:io';

import 'package:flutter_clean_arch_template/core/logger/formatters/log_formatter.dart';
import 'package:flutter_clean_arch_template/core/logger/log_context.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 文件日志观察器
/// 负责将日志持久化到本地文件
class FileObserver extends TalkerObserver {
  FileObserver({
    required this.context,
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFiles = 5,
  });

  final LogContext context;
  final int maxFileSize;
  final int maxFiles;

  File? _currentLogFile;
  IOSink? _logSink;
  int _currentFileSize = 0;
  bool _isInitialized = false;

  /// 初始化文件观察器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final directory = await _getLogDirectory();
      await _rotateLogFilesIfNeeded(directory);
      await _openLogFile(directory);
      _isInitialized = true;
    } catch (e) {
      // 初始化失败时静默处理，不影响应用运行
    }
  }

  @override
  void onLog(TalkerData data) {
    if (!_isInitialized) return;

    _writeToFile(data);
  }

  @override
  void onError(TalkerError error) {
    if (!_isInitialized) return;

    _writeToFile(error);
  }

  @override
  void onException(TalkerException exception) {
    if (!_isInitialized) return;

    _writeToFile(exception);
  }

  /// 写入日志到文件
  Future<void> _writeToFile(TalkerData data) async {
    try {
      if (_logSink == null) return;

      final formatted = LogFormatter.format(data, context);
      final line = '$formatted\n';
      final bytes = line.length;

      _logSink!.write(line);
      await _logSink!.flush();

      _currentFileSize += bytes;

      // 检查是否需要轮转文件
      if (_currentFileSize >= maxFileSize) {
        await _rotateLogFiles();
      }
    } catch (e) {
      // 写入失败时静默处理
    }
  }

  /// 获取日志目录
  Future<Directory> _getLogDirectory() async {
    // 使用缓存目录，避免占用过多存储空间
    final appDir = await getApplicationCacheDirectory();
    final logDir = Directory('${appDir.path}/logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    return logDir;
  }

  /// 打开日志文件
  Future<void> _openLogFile(Directory directory) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'app_log_$timestamp.log';
    _currentLogFile = File('${directory.path}/$fileName');

    _logSink = _currentLogFile!.openWrite(mode: FileMode.append);
    _currentFileSize = await _currentLogFile!.length();
  }

  /// 轮转日志文件
  Future<void> _rotateLogFiles() async {
    try {
      // 关闭当前文件
      await _logSink?.close();

      final directory = await _getLogDirectory();

      // 清理旧日志
      await _cleanOldLogs(directory);

      // 打开新文件
      await _openLogFile(directory);
    } catch (e) {
      // 轮转失败时静默处理
    }
  }

  /// 检查并轮转日志文件（如果需要）
  Future<void> _rotateLogFilesIfNeeded(Directory directory) async {
    try {
      final files = await _getLogFiles(directory);

      if (files.isEmpty) return;

      // 获取最新的日志文件
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latestFile = files.first;
      final fileSize = await latestFile.length();

      // 如果最新文件已满，进行轮转
      if (fileSize >= maxFileSize) {
        await _cleanOldLogs(directory);
      }
    } catch (e) {
      // 检查失败时静默处理
    }
  }

  /// 清理旧日志文件
  Future<void> _cleanOldLogs(Directory directory) async {
    try {
      final files = await _getLogFiles(directory);

      if (files.length <= maxFiles) return;

      // 按修改时间排序（最新的在前）
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // 删除超出限制的旧文件
      for (var i = maxFiles; i < files.length; i++) {
        await files[i].delete();
      }
    } catch (e) {
      // 清理失败时静默处理
    }
  }

  /// 获取所有日志文件
  Future<List<File>> _getLogFiles(Directory directory) async {
    final files = <File>[];

    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.log')) {
        files.add(entity);
      }
    }

    return files;
  }

  /// 关闭文件观察器
  Future<void> dispose() async {
    await _logSink?.close();
    _logSink = null;
    _currentLogFile = null;
    _isInitialized = false;
  }
}
