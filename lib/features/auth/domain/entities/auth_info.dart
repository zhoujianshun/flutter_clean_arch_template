import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_info.freezed.dart';
part 'auth_info.g.dart';

@freezed
abstract class AuthInfo with _$AuthInfo {
  const factory AuthInfo({
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
  }) = _AuthInfo;

  factory AuthInfo.fromJson(Map<String, dynamic> json) => _$AuthInfoFromJson(json);
}
