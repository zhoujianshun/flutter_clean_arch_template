/// API 成功码判定策略
///
/// 将 "哪些 code 视为成功" 的硬编码抽象为可配置策略，
/// 避免业务码规范变化时需要修改 Freezed 生成类。
///
/// 默认策略：`code == 200`。
///
/// 可在应用初始化阶段覆盖：
/// ```dart
/// ApiSuccessPolicy.instance = ApiSuccessPolicy(successCodes: {0, 200, 201});
/// ```
class ApiSuccessPolicy {
  ApiSuccessPolicy({
    this.successCodes = const {200},
  });

  /// 全局单例，可在应用初始化时替换
  static ApiSuccessPolicy instance = ApiSuccessPolicy();

  /// 被视为成功的业务状态码集合
  final Set<int> successCodes;

  /// 判断给定的业务状态码是否表示成功
  bool isSuccess(int code) => successCodes.contains(code);
}
