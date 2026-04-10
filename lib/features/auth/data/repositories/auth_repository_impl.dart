import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_clean_arch_template/core/network/token/token_manager.dart';
import 'package:flutter_clean_arch_template/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/auth_info_model.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/phone_login_request.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/get_current_user_info/current_user_info_model.dart';
// ignore: unused_import — mirrors datasource contract / future repository methods
import 'package:flutter_clean_arch_template/features/auth/data/models/send_verification_code/send_verification_code_request.dart';
import 'package:flutter_clean_arch_template/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._tokenManager);

  final UserRemoteDataSource _remoteDataSource;
  final TokenManager _tokenManager;

  @override
  Future<Either<Failure, AuthInfoModel>> phoneLogin(PhoneLoginRequest request) async {
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

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (e) {
      AppLogger.warning('Remote logout failed: $e');
    }
    await clearAuthData();
    return const Right(null);
  }

  @override
  Future<Either<Failure, CurrentUserInfoModel>> getCurrentUser() async {
    return _remoteDataSource.getCurrentUser();
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
