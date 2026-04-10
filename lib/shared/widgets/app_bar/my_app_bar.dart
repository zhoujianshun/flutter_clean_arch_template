import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

extension AppBarExtension on AppBar {
  static AppBar primary({required BuildContext context, required String title}) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(title),
      elevation: 0,
      foregroundColor: AppAdaptiveColors.neutral100(context),
      backgroundColor: theme.primaryColor,
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        color: AppAdaptiveColors.neutral100(context),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark, // iOS
        statusBarIconBrightness: Brightness.light, // Android
      ),
    );
  }

  static AppBar defaultAppBar({required BuildContext context, required String title}) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(title),
      elevation: 0,
      foregroundColor: AppAdaptiveColors.neutral800(context),
      backgroundColor: AppAdaptiveColors.neutral100(context),
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        color: AppAdaptiveColors.neutral800(context),
      ),
      // systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  static AppBar bgColorAppBar({required BuildContext context, required String title}) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(title),
      elevation: 0,
      foregroundColor: AppAdaptiveColors.neutral800(context),
      backgroundColor: AppAdaptiveColors.neutral50(context),
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        color: AppAdaptiveColors.neutral800(context),
      ),
      // systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }
}
