import 'dart:ui';

import 'package:flutter_clean_arch_template/core/constants/storage_keys.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/storage/storage_service.dart';

/// 支持的语言枚举
enum AppLanguage {
  chinese(Locale('zh', 'CN'), '中文', '🇨🇳'),
  english(Locale('en'), 'English', '🇺🇸');

  const AppLanguage(this.locale, this.displayName, this.flag);

  final Locale locale;
  final String displayName;

  /// 旗帜 emoji，用于 UI 展示
  final String flag;

  /// 从 Locale 获取 AppLanguage
  ///
  /// 仅按 languageCode 匹配：系统 locale（如 en_US）的 countryCode
  /// 与枚举定义（Locale('en')）不一致，双条件比较会把英文系统误判为中文
  static AppLanguage fromLocale(Locale locale) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.locale.languageCode == locale.languageCode,
      orElse: () => AppLanguage.chinese, // 默认中文
    );
  }

  /// 从语言代码获取 AppLanguage
  static AppLanguage fromLanguageCode(String languageCode) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.locale.languageCode == languageCode,
      orElse: () => AppLanguage.chinese, // 默认中文
    );
  }
}

/// 语言服务类
class LanguageService {
  /// 获取保存的语言设置（同步）
  ///
  /// 返回 null 表示无保存值（调用方应回退到系统语言）。
  /// StorageService 未就绪或读取失败时也返回 null，不抛出。
  static AppLanguage? getSavedLanguageSync() {
    try {
      final languageCode =
          ServiceLocator.getOrNull<StorageService>()?.getSetting(StorageKeys.appLanguage);
      if (languageCode != null) {
        return AppLanguage.fromLanguageCode(languageCode);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 获取用户保存的语言偏好，无保存值时回退到系统语言
  static AppLanguage getSavedOrSystemLanguage() {
    return getSavedLanguageSync() ?? systemLanguage;
  }

  /// 保存语言设置
  static Future<void> saveLanguage(AppLanguage language) async {
    try {
      await ServiceLocator.getOrNull<StorageService>()?.setSetting(
        StorageKeys.appLanguage,
        language.locale.languageCode,
      );
    } catch (e) {
      AppLogger.warning('语言偏好保存失败，下次启动将回退系统语言', error: e);
    }
  }

  /// 系统语言（仅按 languageCode 匹配，未知语言回退中文）
  ///
  /// 统一的系统语言读取入口：Provider 初始化、网络层语言头等
  /// 场景共用，避免回退逻辑多处重复后漂移不一致。
  static AppLanguage get systemLanguage {
    return AppLanguage.fromLocale(PlatformDispatcher.instance.locale);
  }

  /// 清除保存的语言设置
  static Future<void> clearSavedLanguage() async {
    try {
      await ServiceLocator.getOrNull<StorageService>()?.removeSetting(
        StorageKeys.appLanguage,
      );
    } catch (e) {
      AppLogger.warning('语言偏好清除失败', error: e);
    }
  }
}
