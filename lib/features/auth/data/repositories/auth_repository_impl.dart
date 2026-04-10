import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_manager.dart';
import 'package:flutter_clean_arch_template/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/auth_info_model.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/phone_login_request.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/get_current_user_info/current_user_info_model.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._tokenManager);

  final UserRemoteDataSource _remoteDataSource;
  final TokenManager _tokenManager;

  @override
  Future<Either<Failure, AuthInfoModel>> phoneLogin(PhoneLoginRequest request) async {
    if (AppConfig.mockAuth) {
      return _mockLogin(request);
    }

    final result = await _remoteDataSource.phoneLogin(request);
    return result.fold(
      Left.new,
      (authInfo) async {
        await _tokenManager.saveToken(
          accessToken: authInfo.accessToken,
          refreshToken: authInfo.refreshToken,
        );
        AppLogger.info('User logged in successfully');
        return Right(authInfo);
      },
    );
  }

  Future<Either<Failure, AuthInfoModel>> _mockLogin(PhoneLoginRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    AppLogger.info('[MOCK] Simulating login for ${request.phonenumber}');

    const mockAuth = AuthInfoModel(
      accessToken: 'mock_access_token_demo_123',
      refreshToken: 'mock_refresh_token_demo_456',
      expiresIn: 86400,
    );

    await _tokenManager.saveToken(
      accessToken: mockAuth.accessToken,
      refreshToken: mockAuth.refreshToken,
    );

    AppLogger.info('[MOCK] User logged in successfully');
    return const Right(mockAuth);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    if (!AppConfig.mockAuth) {
      try {
        await _remoteDataSource.logout();
      } catch (e) {
        AppLogger.warning('Remote logout failed: $e');
      }
    }
    await clearAuthData();
    return const Right(null);
  }

  @override
  Future<Either<Failure, CurrentUserInfoModel>> getCurrentUser() async {
    if (AppConfig.mockAuth) {
      return _mockGetCurrentUser();
    }
    return _remoteDataSource.getCurrentUser();
  }

  Future<Either<Failure, CurrentUserInfoModel>> _mockGetCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    const mockUser = CurrentUserInfoModel(
      userId: 'mock_user_001',
      nickName: 'Demo User',
      phonenumber: '13800138000',
      avatar: '',
    );
    return const Right(mockUser);
  }

  @override
  Future<bool> isUserLoggedIn() async {
    final token = await _tokenManager.getValidToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> clearAuthData() async {
    await _tokenManager.clearToken();
    AppLogger.info('Auth data cleared');
  }
}
