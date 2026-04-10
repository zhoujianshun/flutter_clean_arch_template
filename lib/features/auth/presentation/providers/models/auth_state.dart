import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

enum AuthStateChangeReason {
  loginSuccess,
  loginFailed,
  logoutCompleted,
  tokenExpired,
  authenticationFailed,
  appInitializedNoToken,
  appInitializedWithToken,
  userInfoLoaded,
  userInfoLoadFailed,
  dataCleared,
  userInitiated,
}

enum LogoutReason {
  userInitiated,
  tokenExpired,
  authenticationFailed,
  forced,
}

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    String? accessToken,
    String? errorMessage,
    AuthStateChangeReason? changeReason,
    DateTime? changeTime,
    String? changeContext,
    LogoutReason? logoutReason,
  }) = _AuthState;
}
