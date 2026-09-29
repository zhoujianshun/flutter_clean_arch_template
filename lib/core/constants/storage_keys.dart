class StorageKeys {
  // 认证相关Keys
  static const String authInfo = 'auth_info';
  static const String userTokenKey = 'user_token';
  static const String userInfoKey = 'user_info';
  static const String refreshTokenKey = 'refresh_token';

  // 应用状态Keys
  static const String isFirstLaunch = 'is_first_launch';
  static const String onboardingCompleted = 'onboarding_completed';

  // 应用设置Keys（SharedPreferences）
  static const String themeMode = 'theme_mode';
  static const String appLanguage = 'app_language';

  // 隐私协议Keys
  static const String privacyPolicyAgreed = 'privacy_policy_agreed';

  // 环境配置Keys
  static const String selectedEnvironment = 'selected_environment';

  // 版本更新Keys
  static const String ignoredUpdateVersion = 'ignored_update_version';
}
