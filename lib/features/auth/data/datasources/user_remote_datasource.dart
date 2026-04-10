import 'package:dartz/dartz.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/network/base_api.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/auth_info_model.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/auth/phone_login_request.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/get_current_user_info/current_user_info_model.dart';
import 'package:flutter_clean_arch_template/features/auth/data/models/send_verification_code/send_verification_code_request.dart';
import 'package:injectable/injectable.dart';

class UserApiEndpoints {
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String userInfo = '/user/info';
  static const String smsCode = '/resource/sms/code';
}

@Injectable()
class UserRemoteDataSource extends BaseAPI {
  UserRemoteDataSource(super.apiClient);

  Future<Either<Failure, CurrentUserInfoModel>> getCurrentUser() async {
    return handleApiCall(
      apiClient.get(UserApiEndpoints.userInfo),
      CurrentUserInfoModel.fromJson,
      logTag: 'UserRemoteDataSource.getCurrentUser',
    );
  }

  Future<Either<Failure, void>> logout() async {
    return handleApiVoidCall(
      apiClient.post(UserApiEndpoints.logout),
      logTag: 'UserRemoteDataSource.logout',
    );
  }

  Future<Either<Failure, AuthInfoModel>> phoneLogin(PhoneLoginRequest request) async {
    return handleApiCall(
      apiClient.post(UserApiEndpoints.login, data: request.toJson()),
      AuthInfoModel.fromJson,
      logTag: 'UserRemoteDataSource.phoneLogin',
    );
  }

  Future<Either<Failure, void>> sendVerificationCode(SendVerificationCodeRequest request) async {
    final data = request.toJson();
    addTimestampToQueryParameters(data);
    return handleApiVoidCall(
      apiClient.get(UserApiEndpoints.smsCode, queryParameters: data),
      logTag: 'UserRemoteDataSource.sendVerificationCode',
    );
  }
}
