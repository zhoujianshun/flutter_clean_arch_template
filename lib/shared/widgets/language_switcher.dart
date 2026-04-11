import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/l10n/app_language.dart';
import 'package:flutter_clean_arch_template/core/l10n/language_provider.dart';
import 'package:flutter_clean_arch_template/generated/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 语言切换器组件
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
  });

  /// 是否显示标签
  final bool showLabel;

  /// 是否使用紧凑模式
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(appLanguageSettingProvider);
    final l10n = AppLocalizations.of(context);

    if (isCompact) {
      return _buildCompactSwitcher(context, ref, currentLanguage, l10n);
    }

    return _buildFullSwitcher(context, ref, currentLanguage, l10n);
  }

  /// 构建完整的语言切换器
  Widget _buildFullSwitcher(
    BuildContext context,
    WidgetRef ref,
    AppLanguage currentLanguage,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            l10n.profile_language,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...AppLanguage.values.map((language) {
          final isSelected = language == currentLanguage;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _changeLanguage(ref, language),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // 语言图标
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getLanguageFlag(language),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 语言名称
                    Expanded(
                      child: Text(
                        language.displayName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ),
                    // 选中指示器
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 构建紧凑的语言切换器（下拉菜单形式）
  Widget _buildCompactSwitcher(
    BuildContext context,
    WidgetRef ref,
    AppLanguage currentLanguage,
    AppLocalizations l10n,
  ) {
    return PopupMenuButton<AppLanguage>(
      initialValue: currentLanguage,
      onSelected: (language) => _changeLanguage(ref, language),
      itemBuilder: (context) => AppLanguage.values.map((language) {
        final isSelected = language == currentLanguage;
        return PopupMenuItem<AppLanguage>(
          value: language,
          child: Row(
            children: [
              Text(
                _getLanguageFlag(language),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                language.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getLanguageFlag(currentLanguage),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              currentLanguage.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换语言
  Future<void> _changeLanguage(WidgetRef ref, AppLanguage language) async {
    await ref.read(appLanguageSettingProvider.notifier).changeLanguage(language);
  }

  /// 获取语言对应的旗帜表情符号
  String _getLanguageFlag(AppLanguage language) {
    switch (language) {
      case AppLanguage.chinese:
        return '🇨🇳';
      case AppLanguage.english:
        return '🇺🇸';
    }
  }
}

/// 语言切换对话框
class LanguageSwitcherDialog extends ConsumerWidget {
  const LanguageSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.profile_language),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: const LanguageSwitcher(showLabel: false),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_confirm),
        ),
      ],
    );
  }

  /// 显示语言切换对话框
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const LanguageSwitcherDialog(),
    );
  }
}

/// 简单的语言切换按钮
class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({
    super.key,
    this.onPressed,
  });

  /// 点击回调
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(appLanguageSettingProvider);

    return IconButton(
      onPressed: onPressed ?? () => LanguageSwitcherDialog.show(context),
      icon: CircleAvatar(
        radius: 12,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Text(
          _getLanguageFlag(currentLanguage),
          style: const TextStyle(fontSize: 12),
        ),
      ),
      tooltip: AppLocalizations.of(context).profile_language,
    );
  }

  /// 获取语言对应的旗帜表情符号
  String _getLanguageFlag(AppLanguage language) {
    switch (language) {
      case AppLanguage.chinese:
        return '🇨🇳';
      case AppLanguage.english:
        return '🇺🇸';
    }
  }
}
