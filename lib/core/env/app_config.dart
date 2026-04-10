import 'package:flutter/foundation.dart';
import 'package:flutter_clean_arch_template/core/env/env_config_manager.dart';

/// Application environment configuration
///
/// All values are loaded from .env files via [EnvConfigManager].
/// Override defaults by editing `assets/env/.env.*` files.
class AppConfig {
  AppConfig._();

  static bool get isDebug {
    return EnvConfigManager.getBool('DEBUG', defaultValue: kDebugMode);
  }

  static String get logLevel {
    return EnvConfigManager.getString(
      'LOG_LEVEL',
      defaultValue: kDebugMode ? 'debug' : 'error',
    );
  }

  static String get environment {
    return EnvConfigManager.getString(
      'ENVIRONMENT',
      defaultValue: kDebugMode ? 'development' : 'production',
    );
  }

  static String get baseUrl {
    return EnvConfigManager.getString(
      'API_BASE_URL',
      defaultValue: 'https://api.example.com',
    );
  }

  static String get clientId {
    return EnvConfigManager.getString(
      'CLIENT_ID',
      defaultValue: 'your_client_id_here',
    );
  }

  static int get connectTimeout {
    return EnvConfigManager.getInt('CONNECT_TIMEOUT', defaultValue: 30000);
  }

  static int get receiveTimeout {
    return EnvConfigManager.getInt('RECEIVE_TIMEOUT', defaultValue: 30000);
  }

  static bool get enableTalkerScreen {
    return EnvConfigManager.getBool(
      'ENABLE_TALKER_SCREEN',
      defaultValue: kDebugMode,
    );
  }

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';

  static String get environmentDisplayName {
    switch (environment) {
      case 'production':
        return 'Production';
      case 'staging':
        return 'Staging';
      case 'development':
      default:
        return 'Development';
    }
  }

  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': environment,
      'displayName': environmentDisplayName,
      'isDebug': isDebug,
      'logLevel': logLevel,
      'clientId': clientId,
      'enableTalkerScreen': enableTalkerScreen,
      'networkConfig': {
        'baseUrl': baseUrl,
        'connectTimeout': connectTimeout,
        'receiveTimeout': receiveTimeout,
      },
    };
  }
}
