import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_clean_arch_template/core/l10n/app_language.dart';

part 'language_provider.g.dart';

/// 语言状态管理器
///
/// 生成的 Provider: appLanguageSettingProvider
@Riverpod(keepAlive: true)
class AppLanguageSetting extends _$AppLanguageSetting {
  @override
  AppLanguage build() {
    // _loadSavedLanguage();
    // 默认是中文，不允许切换语言
    return AppLanguage.chinese;
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
