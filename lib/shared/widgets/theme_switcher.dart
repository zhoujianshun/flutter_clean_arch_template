import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/theme_mode_provider.dart';
import 'package:flutter_clean_arch_template/generated/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题切换Widget - 支持多种样式
class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({
    super.key,
    this.style = ThemeSwitcherStyle.listTile,
    this.showLabel = true,
  });

  final ThemeSwitcherStyle style;
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final themeModeNotifier = ref.read(appThemeModeProvider.notifier);
    final l10n = AppLocalizations.of(context);

    switch (style) {
      case ThemeSwitcherStyle.listTile:
        return _buildListTile(context, themeMode, themeModeNotifier, l10n);
      case ThemeSwitcherStyle.iconButton:
        return _buildIconButton(context, themeMode, themeModeNotifier);
      case ThemeSwitcherStyle.segmentedButton:
        return _buildSegmentedButton(context, themeMode, themeModeNotifier, l10n);
      case ThemeSwitcherStyle.dropdown:
        return _buildDropdown(context, themeMode, themeModeNotifier, l10n);
    }
  }

  /// 构建列表项样式的主题切换器
  Widget _buildListTile(
    BuildContext context,
    ThemeMode themeMode,
    AppThemeMode notifier,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: Icon(notifier.getThemeModeIcon()),
      title: Text(l10n.profile_theme),
      subtitle: Text(notifier.getThemeModeDisplayName()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeSelectionDialog(context, themeMode, notifier, l10n),
    );
  }

  /// 构建图标按钮样式的主题切换器
  Widget _buildIconButton(
    BuildContext context,
    ThemeMode themeMode,
    AppThemeMode notifier,
  ) {
    return IconButton(
      icon: Icon(notifier.getThemeModeIcon()),
      tooltip: notifier.getThemeModeDisplayName(),
      onPressed: () => notifier.toggleThemeMode(),
    );
  }

  /// 构建分段按钮样式的主题切换器
  Widget _buildSegmentedButton(
    BuildContext context,
    ThemeMode themeMode,
    AppThemeMode notifier,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            l10n.profile_theme,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
        ],
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text(l10n.theme_system),
              icon: const Icon(Icons.brightness_auto),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text(l10n.theme_light),
              icon: const Icon(Icons.light_mode),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text(l10n.theme_dark),
              icon: const Icon(Icons.dark_mode),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (newSelection) {
            if (newSelection.isNotEmpty) {
              notifier.setThemeMode(newSelection.first);
            }
          },
        ),
      ],
    );
  }

  /// 构建下拉菜单样式的主题切换器
  Widget _buildDropdown(
    BuildContext context,
    ThemeMode themeMode,
    AppThemeMode notifier,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            l10n.profile_theme,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<ThemeMode>(
          initialValue: themeMode,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: [
                  const Icon(Icons.brightness_auto, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.theme_system),
                ],
              ),
            ),
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: [
                  const Icon(Icons.light_mode, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.theme_light),
                ],
              ),
            ),
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  const Icon(Icons.dark_mode, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.theme_dark),
                ],
              ),
            ),
          ],
          onChanged: (newValue) {
            if (newValue != null) {
              notifier.setThemeMode(newValue);
            }
          },
        ),
      ],
    );
  }

  /// 显示主题选择对话框
  Future<void> _showThemeSelectionDialog(
    BuildContext context,
    ThemeMode currentMode,
    AppThemeMode notifier,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profile_theme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                ThemeMode.system,
                l10n.theme_system,
                Icons.brightness_auto,
                currentMode,
              ),
              _buildThemeOption(
                context,
                ThemeMode.light,
                l10n.theme_light,
                Icons.light_mode,
                currentMode,
              ),
              _buildThemeOption(
                context,
                ThemeMode.dark,
                l10n.theme_dark,
                Icons.dark_mode,
                currentMode,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_cancel),
            ),
          ],
        );
      },
    );

    if (result != null) {
      notifier.setThemeMode(result);
    }
  }

  /// 构建主题选项
  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
    ThemeMode currentMode,
  ) {
    final isSelected = mode == currentMode;

    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: currentMode,
      onChanged: (value) {
        if (value != null) {
          Navigator.of(context).pop(value);
        }
      },
      title: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

/// 主题切换器样式枚举
enum ThemeSwitcherStyle {
  /// 列表项样式 - 适用于设置页面
  listTile,

  /// 图标按钮样式 - 适用于工具栏
  iconButton,

  /// 分段按钮样式 - 适用于设置面板
  segmentedButton,

  /// 下拉菜单样式 - 适用于表单
  dropdown,
}

/// 主题切换浮动按钮 - 用于快速切换
class ThemeToggleFab extends ConsumerWidget {
  const ThemeToggleFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeNotifier = ref.read(appThemeModeProvider.notifier);

    return FloatingActionButton(
      onPressed: themeModeNotifier.toggleThemeMode,
      child: Icon(themeModeNotifier.getThemeModeIcon()),
    );
  }
}

/// 应用栏主题切换按钮
class AppBarThemeButton extends ConsumerWidget {
  const AppBarThemeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ThemeSwitcher(
      style: ThemeSwitcherStyle.iconButton,
      showLabel: false,
    );
  }
}
