/// Configuration for authentication-related network behavior.
///
/// Registered via GetIt. Feature layers can override with their own paths.
///
/// Example registration in service_locator.dart:
/// ```dart
/// getIt.registerSingleton<AuthConfig>(
///   const AuthConfig(publicPaths: ['/auth/login', '/resource/sms/code']),
/// );
/// ```
class AuthConfig {
  const AuthConfig({this.publicPaths = const []});

  /// API paths that do not require authentication tokens.
  final List<String> publicPaths;
}
