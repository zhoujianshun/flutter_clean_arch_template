/// Controls how the app handles authentication requirements.
///
/// - [required]: All pages require login (except explicit whitelist).
///   Unauthenticated users are redirected to the login page.
/// - [optional]: App launches into the home page by default.
///   Only pages listed in `AuthGuard.authRequiredRoutes` require login.
enum AuthMode {
  required,
  optional;

  static AuthMode fromString(String value) {
    return AuthMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuthMode.required,
    );
  }
}
