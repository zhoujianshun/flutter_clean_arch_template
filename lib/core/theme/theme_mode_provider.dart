import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/di/service_locator.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/storage/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// 主题模式状态管理器 - 支持持久化存储
///
/// 生成的 Provider: appThemeModeProvider
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    // 异步加载主题设置
    // _loadThemeMode();
    // 默认是浅色主题，不允许切换主题
    return ThemeMode.light;
  }

  /// 从本地存储加载主题模式
  Future<void> loadThemeMode() async {
    try {
      final storageService = getIt<StorageService>();
      final savedTheme = storageService.getSetting(_themeKey);
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            state = ThemeMode.light;
          case 'dark':
            state = ThemeMode.dark;
          case 'system':
          default:
            state = ThemeMode.system;
        }
        AppLogger.debug('主题模式已加载: $savedTheme');
      }
    } catch (e, stackTrace) {
      AppLogger.warning('加载主题偏好失败，使用默认主题', error: e, stackTrace: stackTrace);
      state = ThemeMode.system;
    }
  }

  /// 切换到下一个主题模式
  Future<void> toggleThemeMode() async {
    ThemeMode newMode;
    switch (state) {
      case ThemeMode.system:
        newMode = ThemeMode.light;
      case ThemeMode.light:
        newMode = ThemeMode.dark;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
    }
    await setThemeMode(newMode);
  }

  /// 设置特定的主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemeMode(mode);
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      String modeString;
      switch (mode) {
        case ThemeMode.light:
          modeString = 'light';
        case ThemeMode.dark:
          modeString = 'dark';
        case ThemeMode.system:
          modeString = 'system';
      }

      await getIt<StorageService>().setSetting(_themeKey, modeString);
      AppLogger.debug('主题模式已保存: $modeString');
    } catch (e, stackTrace) {
      AppLogger.warning('保存主题模式失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 获取当前主题模式的显示名称
  String getThemeModeDisplayName() {
    switch (state) {
      case ThemeMode.light:
        return '浅色主题';
      case ThemeMode.dark:
        return '深色主题';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  /// 获取当前主题模式的图标
  IconData getThemeModeIcon() {
    switch (state) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
