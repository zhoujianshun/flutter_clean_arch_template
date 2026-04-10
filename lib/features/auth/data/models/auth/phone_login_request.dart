import 'package:freezed_annotation/freezed_annotation.dart';

part 'phone_login_request.freezed.dart';
part 'phone_login_request.g.dart';

@freezed
abstract class PhoneLoginRequest with _$PhoneLoginRequest {
  const factory PhoneLoginRequest({
    @JsonKey(name: 'clientId') required String clientId,
    @JsonKey(name: 'grantType') required String grantType,
    required String phonenumber,
    @JsonKey(name: 'smsCode') required String smsCode,
  }) = _PhoneLoginRequest;

  factory PhoneLoginRequest.fromJson(Map<String, dynamic> json) => _$PhoneLoginRequestFromJson(json);
}
