import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/auth_info_model.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/phone_login_request.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/get_current_user_info/current_user_info_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthInfoModel>> phoneLogin(PhoneLoginRequest request);
  Future<Either<Failure, void>> sendVerificationCode(String phonenumber);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, CurrentUserInfoModel>> getCurrentUser();
  Future<bool> isUserLoggedIn();
  Future<void> clearAuthData();
}
