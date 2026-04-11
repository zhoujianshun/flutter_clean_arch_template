import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/core/constants/storage_keys.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EnvType {
  development('development', 'dev', '开发', 'assets/env/.env.development'),
  staging('staging', 'staging', '预发布', 'assets/env/.env.staging'),
  production('production', 'prod', '生产', 'assets/env/.env.production');

  const EnvType(this.value, this.flavor, this.displayName, this.envFile);

  final String value;
  final String flavor;
  final String displayName;
  final String envFile;
}

/// 环境配置管理器
/// 负责加载和合并不同环境的配置文件
/// 基于 flutter_dotenv 6.0.0+ 官方最佳实践实现
class EnvConfigManager {
  EnvConfigManager._();

  static bool _isInitialized = false;
  static SharedPreferences? _sharedPreferences;

  /// 初始化环境配置
  /// 使用官方推荐的 overrideWith 参数实现环境配置合并：
  /// 1. 加载基础 .env 文件
  /// 2. 根据环境加载对应的环境配置文件，使用 overrideWith 覆盖基础配置
  static Future<void> initialize({String? environment}) async {
    if (_isInitialized) {
      return;
    }

    try {
      // 初始化 SharedPreferences，不要使用项目中的 SharedPrefsService，此时还未初始化
      if (checkCanEditEnv()) {
        _sharedPreferences ??= await SharedPreferences.getInstance();
      }

      // 确定当前环境
      final currentEnv = (environment ?? _determineEnvironment()).trim().toLowerCase();
      const defaultEnvFile = 'assets/env/.env';
      // 获取存在的环境特定配置文件
      final existingEnvFiles = await _getExistingEnvFiles(currentEnv);

      try {
        await dotenv.load(
          fileName: defaultEnvFile,
          // 前面的文件后加载，所以要reversed
          overrideWithFiles: existingEnvFiles.reversed.toList(),
        );

        AppLogger.info('已加载环境配置文件: $existingEnvFiles');
      } catch (e) {
        AppLogger.error('无法加载环境配置文件: $defaultEnvFile，$existingEnvFiles', error: e, stackTrace: StackTrace.current);
      }

      _isInitialized = true;

      AppLogger.info('环境配置初始化完成');
      AppLogger.info('当前环境: $currentEnv');
      AppLogger.info('API地址: ${dotenv.env['API_BASE_URL'] ?? 'Not configured'}');
      AppLogger.info('环境信息: ${AppConfig.getEnvironmentInfo()}');
    } catch (e) {
      AppLogger.error('环境配置初始化失败', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  /// 确定当前环境
  static String _determineEnvironment() {
    // 1. 从本地存储中获取用户选择的环境（仅在允许编辑时）
    if (_sharedPreferences != null && checkCanEditEnv()) {
      try {
        final savedEnv = _sharedPreferences?.getString(StorageKeys.selectedEnvironment);
        if (savedEnv != null && savedEnv.isNotEmpty) {
          AppLogger.info('使用本地保存的环境: $savedEnv');
          return savedEnv;
        }
      } catch (e) {
        AppLogger.error('读取本地保存环境失败', error: e, stackTrace: StackTrace.current);
      }
    }

    // 2. 优先从环境变量中获取（最高优先级，用于强制覆盖）
    const envFromConst = String.fromEnvironment('ENVIRONMENT');
    if (envFromConst.isNotEmpty) {
      AppLogger.info('使用环境变量指定的环境: $envFromConst');
      return envFromConst;
    }

    // 3. 从命令行参数中获取
    const flavorFromConst = String.fromEnvironment('FLAVOR');
    if (flavorFromConst.isNotEmpty) {
      AppLogger.info('使用命令行参数指定的环境: $flavorFromConst');
      return flavorFromConst;
    }

    // 4. 根据编译模式确定默认环境
    if (kDebugMode) {
      return 'development';
    } else if (kProfileMode) {
      return 'staging';
    } else {
      return 'production';
    }
  }

  static EnvType _getEnvType(String environment) {
    return EnvType.values.firstWhere(
      (e) => e.value == environment || e.flavor == environment,
      orElse: () => EnvType.production,
    );
  }

  /// 根据环境获取对应的配置文件路径列表
  /// 只返回存在的配置文件，避免加载不存在的文件导致启动失败
  static Future<List<String>> _getExistingEnvFiles(String environment) async {
    final baseEnvFile = _getEnvType(environment).envFile;

    final existingFiles = <String>[];

    // 检查基础环境文件是否存在
    if (await _fileExists(baseEnvFile)) {
      existingFiles.add(baseEnvFile);
    }

    // 检查本地覆盖文件是否存在（优先级更高，所以放在后面）
    final localFile = '$baseEnvFile.local';
    if (await _fileExists(localFile)) {
      existingFiles.add(localFile);
    }

    return existingFiles;
  }

  /// 检查文件是否存在
  static Future<bool> _fileExists(String filePath) async {
    try {
      await rootBundle.loadString(filePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否可以编辑环境, 从环境变量EDIT_ENV中获取
  static bool checkCanEditEnv() {
    const editEnv = String.fromEnvironment('EDIT_ENV');
    AppLogger.info('检查是否可以编辑环境: $editEnv');
    return editEnv == 'true';
  }

  /// 获取字符串配置值
  /// 使用官方 API，支持 fallback 和严格模式
  static String getString(String key, {String? defaultValue}) {
    _checkInitialized();
    if (defaultValue != null) {
      return dotenv.get(key, fallback: defaultValue);
    }
    return dotenv.get(key);
  }

  /// 获取可选字符串配置值（可能返回 null）
  static String? maybeGetString(String key, {String? fallback}) {
    _checkInitialized();
    return dotenv.maybeGet(key, fallback: fallback);
  }

  /// 获取布尔配置值
  /// 使用官方提供的类型化 getBool 方法
  static bool getBool(String key, {bool? defaultValue}) {
    _checkInitialized();
    if (defaultValue != null) {
      return dotenv.getBool(key, fallback: defaultValue);
    }
    // 如果没有提供默认值，使用 false 作为 fallback
    return dotenv.getBool(key, fallback: false);
  }

  /// 设置布尔配置值
  static Future<void> setBool(String key, bool value) async {
    await setValue(key, '$value');
  }

  /// 获取整数配置值
  /// 使用官方提供的类型化 getInt 方法
  static int getInt(String key, {int? defaultValue}) {
    _checkInitialized();
    if (defaultValue != null) {
      return dotenv.getInt(key, fallback: defaultValue);
    }
    // 如果没有提供默认值，使用 0 作为 fallback
    return dotenv.getInt(key, fallback: 0);
  }

  /// 获取双精度浮点数配置值
  /// 使用官方提供的类型化 getDouble 方法
  static double getDouble(String key, {double? defaultValue}) {
    _checkInitialized();
    if (defaultValue != null) {
      return dotenv.getDouble(key, fallback: defaultValue);
    }
    // 如果没有提供默认值，使用 0.0 作为 fallback
    return dotenv.getDouble(key, fallback: 0);
  }

  /// 检查是否已初始化
  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('EnvConfigManager 尚未初始化。请先调用 EnvConfigManager.initialize()');
    }
  }

  /// 检查配置项是否存在
  static bool hasKey(String key) {
    _checkInitialized();
    return dotenv.env.containsKey(key);
  }

  /// 获取所有环境变量（调试用）
  /// 返回不可变的副本以防止外部修改
  static Map<String, String> getAllEnvVars() {
    _checkInitialized();
    return Map.unmodifiable(dotenv.env);
  }

  /// 安全地获取环境变量用于日志输出
  /// 敏感信息将被遮蔽
  static Map<String, String> getSafeEnvVarsForLogging() {
    _checkInitialized();
    final safeVars = <String, String>{};
    final sensitiveKeys = {'CLIENT_ID', 'API_KEY', 'SECRET', 'TOKEN', 'PASSWORD'};

    for (final entry in dotenv.env.entries) {
      final isSensitive = sensitiveKeys.any(
        (sensitive) => entry.key.toUpperCase().contains(sensitive),
      );

      if (isSensitive) {
        safeVars[entry.key] = '***HIDDEN***';
      } else {
        safeVars[entry.key] = entry.value;
      }
    }

    return safeVars;
  }

  /// 从字符串加载配置（主要用于测试）
  /// 直接设置环境变量而不通过文件加载
  static void loadFromString(String content) {
    // 先清理现有状态
    dotenv.clean();

    // 手动解析环境变量字符串并直接设置到 dotenv.env
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        // 直接设置环境变量
        dotenv.env[key] = value;
      }
    }

    _isInitialized = true;
  }

  /// 重置配置（主要用于测试）
  static void reset() {
    _isInitialized = false;
    dotenv.clean();
  }

  /// 获取当前环境名称
  static String getCurrentEnvironment() {
    _checkInitialized();
    return getString('ENVIRONMENT', defaultValue: 'unknown');
  }

  /// 保存选中的环境到本地存储
  static Future<void> saveSelectedEnvironment(String environment) async {
    if (!checkCanEditEnv()) {
      return;
    }
    try {
      await _sharedPreferences?.setString(StorageKeys.selectedEnvironment, environment);
      AppLogger.info('环境选择已保存: $environment');
    } catch (e) {
      AppLogger.error('保存环境选择失败', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  /// 获取本地存储的环境选择
  static String? getSavedEnvironment() {
    try {
      return _sharedPreferences?.getString(StorageKeys.selectedEnvironment);
    } catch (e) {
      AppLogger.error('读取保存的环境选择失败', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  /// 清除保存的环境选择
  static Future<void> clearSavedEnvironment() async {
    if (!checkCanEditEnv()) {
      return;
    }
    try {
      await _sharedPreferences?.remove(StorageKeys.selectedEnvironment);
      AppLogger.info('已清除保存的环境选择');
    } catch (e) {
      AppLogger.error('清除保存的环境选择失败', error: e, stackTrace: StackTrace.current);
    }
  }

  static Future<void> setValue(String key, String value) async {
    _checkInitialized();
    await dotenv.load(mergeWith: {key: value});
  }
}
