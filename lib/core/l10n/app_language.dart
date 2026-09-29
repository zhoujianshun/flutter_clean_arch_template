import 'dart:ui';

import 'package:flutter_clean_arch_template/core/constants/storage_keys.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/storage/storage_service.dart';

/// 支持的语言枚举
enum AppLanguage {
  chinese(Locale('zh', 'CN'), '中文'),
  english(Locale('en'), 'English');

  const AppLanguage(this.locale, this.displayName);

  final Locale locale;
  final String displayName;

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

  /// 获取保存的语言设置
  /// 无保存值时回退到系统语言
  static Future<AppLanguage> getSavedLanguage() async {
    return getSavedLanguageSync() ?? _getSystemLanguage();
  }

  /// 保存语言设置
  static Future<void> saveLanguage(AppLanguage language) async {
    try {
      await ServiceLocator.getOrNull<StorageService>()?.setSetting(
        StorageKeys.appLanguage,
        language.locale.languageCode,
      );
    } catch (_) {
      // 保存失败时静默处理（下次启动回退系统语言）
    }
  }

  /// 获取系统语言
  static AppLanguage _getSystemLanguage() {
    final systemLocale = PlatformDispatcher.instance.locale;
    return AppLanguage.fromLocale(systemLocale);
  }

  /// 清除保存的语言设置
  static Future<void> clearSavedLanguage() async {
    try {
      await ServiceLocator.getOrNull<StorageService>()?.removeSetting(
        StorageKeys.appLanguage,
      );
    } catch (_) {
      // 清除失败时静默处理
    }
  }
}
