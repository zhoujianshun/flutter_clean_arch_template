import 'dart:ui';

import 'package:flutter_clean_arch_template/core/l10n/app_language.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_provider.g.dart';

/// 语言状态管理器
///
/// 生成的 Provider: appLanguageSettingProvider
@Riverpod(keepAlive: true)
class AppLanguageSetting extends _$AppLanguageSetting {
  @override
  AppLanguage build() {
    // 无保存值时回退系统语言（仅按 languageCode 匹配）
    return LanguageService.getSavedLanguageSync() ?? _getSystemLanguage();
  }

  AppLanguage _getSystemLanguage() {
    return AppLanguage.fromLocale(PlatformDispatcher.instance.locale);
  }

  /// 切换语言
  Future<void> changeLanguage(AppLanguage language) async {
    if (state != language) {
      state = language;
      await LanguageService.saveLanguage(language);
    }
  }

  /// 重置为系统语言
  Future<void> resetToSystemLanguage() async {
    await LanguageService.clearSavedLanguage();
    final systemLanguage = await LanguageService.getSavedLanguage();
    state = systemLanguage;
  }
}

/// 当前语言的 Locale 提供者
@Riverpod(keepAlive: true)
Locale appLocale(Ref ref) {
  final language = ref.watch(appLanguageSettingProvider);
  return language.locale;
}
