import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

/// 支持的语言枚举
enum AppLanguage {
  chinese(Locale('zh', 'CN'), '中文'),
  english(Locale('en'), 'English');

  const AppLanguage(this.locale, this.displayName);

  final Locale locale;
  final String displayName;

  /// 从 Locale 获取 AppLanguage
  static AppLanguage fromLocale(Locale locale) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.locale.languageCode == locale.languageCode && lang.locale.countryCode == locale.countryCode,
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
  static const String _languageKey = 'app_language';

  /// 获取保存的语言设置
  static Future<AppLanguage> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        return AppLanguage.fromLanguageCode(languageCode);
      }

      // 如果没有保存的语言设置，使用系统语言
      return _getSystemLanguage();
    } catch (e) {
      // 如果出错，返回默认语言（中文）
      return AppLanguage.chinese;
    }
  }

  /// 保存语言设置
  static Future<void> saveLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.locale.languageCode);
    } catch (e) {
      // 保存失败时静默处理
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
    } catch (e) {
      // 清除失败时静默处理
    }
  }
}
