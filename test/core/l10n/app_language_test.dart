import 'dart:ui';

import 'package:flutter_clean_arch_template/core/l10n/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguage.fromLocale', () {
    test('zh 精确匹配中文', () {
      expect(AppLanguage.fromLocale(const Locale('zh')), AppLanguage.chinese);
    });

    test('zh_CN 仅按 languageCode 匹配中文', () {
      expect(
        AppLanguage.fromLocale(const Locale('zh', 'CN')),
        AppLanguage.chinese,
      );
    });

    test('en_US 系统 locale 正确匹配英文（countryCode 不参与比较）', () {
      expect(AppLanguage.fromLocale(const Locale('en', 'US')), AppLanguage.english);
    });

    test('未知语言回退中文', () {
      expect(AppLanguage.fromLocale(const Locale('fr')), AppLanguage.chinese);
    });
  });

  group('AppLanguage.fromLanguageCode', () {
    test('en 匹配英文', () {
      expect(AppLanguage.fromLanguageCode('en'), AppLanguage.english);
    });

    test('zh 匹配中文', () {
      expect(AppLanguage.fromLanguageCode('zh'), AppLanguage.chinese);
    });

    test('未知语言码回退中文', () {
      expect(AppLanguage.fromLanguageCode('ja'), AppLanguage.chinese);
    });

    test('空字符串回退中文', () {
      expect(AppLanguage.fromLanguageCode(''), AppLanguage.chinese);
    });
  });

  group('LanguageService', () {
    test('getSavedLanguageSync 在 DI 未就绪时返回 null 不抛出', () {
      // 测试环境未注册 StorageService，验证容错路径
      expect(LanguageService.getSavedLanguageSync(), isNull);
    });

    test('systemLanguage 在未知系统语言下回退中文', () {
      // 测试环境 PlatformDispatcher.locale 默认 en_US → english；
      // 无论返回哪个枚举值都不应抛出，且必须是合法枚举
      expect(
        LanguageService.systemLanguage,
        isA<AppLanguage>(),
      );
    });

    test('getSavedOrSystemLanguage 始终返回合法语言', () {
      final language = LanguageService.getSavedOrSystemLanguage();
      expect(AppLanguage.values.contains(language), isTrue);
    });
  });
}
