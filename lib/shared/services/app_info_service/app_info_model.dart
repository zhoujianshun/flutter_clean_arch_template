import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_info_model.freezed.dart';

/// 应用信息模型
@freezed
abstract class AppInfoModel with _$AppInfoModel {
  const factory AppInfoModel({
    @Default('') String appName,
    @Default('') String packageName,
    @Default('') String version,
    @Default('') String buildNumber,
  }) = _AppInfoModel;

  const AppInfoModel._();

  /// 完整版本信息 (如: 1.0.0+1)
  String get fullVersion => '$version+$buildNumber';

  /// 版本显示文本 (如: v1.0.0)
  String get versionText => 'v$version';

  /// 完整版本显示文本 (如: v1.0.0 (1))
  String get fullVersionText => 'v$version ($buildNumber)';
}
