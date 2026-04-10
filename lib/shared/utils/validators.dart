import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';

/// 通用验证器工具类
class Validators {
  Validators._();

  /// 验证邮箱格式
  static bool isEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email);
  }

  /// 验证手机号格式（中国大陆）
  static bool isPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  /// 验证短信验证码格式,默认4位数字
  static bool isSMSCode(String smsCode, {int length = 4}) {
    // 使用正则表达式验证短信验证码格式，默认4位数字
    if (smsCode.isEmpty) return false;
    final smsCodeRegex = RegExp(r'^\d{' + length.toString() + r'}$');
    return smsCodeRegex.hasMatch(smsCode);
    // final smsCodeRegex = RegExp(r'^\d{${length}}$');
    // return smsCodeRegex.hasMatch(smsCode);
  }

  /// 验证密码强度
  /// 至少8位，包含大小写字母和数字
  static bool isStrongPassword(String password) {
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  /// 验证身份证号格式（18位）
  static bool isIdCard(String idCard) {
    final idCardRegex = RegExp(
      r'^[1-9]\d{5}(18|19|([23]\d))\d{2}((0[1-9])|(10|11|12))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$',
    );
    return idCardRegex.hasMatch(idCard);
  }

  /// 验证URL格式
  static bool isUrl(String url) {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(url);
  }

  /// 验证用户名格式
  /// 4-20位，只能包含字母、数字、下划线
  static bool isUsername(String username) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{4,20}$');
    return usernameRegex.hasMatch(username);
  }

  /// 验证数字格式
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  /// 验证整数格式
  static bool isInteger(String str) {
    return int.tryParse(str) != null;
  }

  /// 验证字符串长度
  static bool isLengthValid(String str, int minLength, [int? maxLength]) {
    if (str.length < minLength) return false;
    if (maxLength != null && str.length > maxLength) return false;
    return true;
  }

  /// 验证中文字符
  static bool isChinese(String str) {
    final chineseRegex = RegExp(r'^[\u4e00-\u9fa5]+$');
    return chineseRegex.hasMatch(str);
  }

  /// 验证银行卡号格式
  static bool isBankCard(String cardNumber) {
    final bankCardRegex = RegExp(r'^\d{16,19}$');
    return bankCardRegex.hasMatch(cardNumber);
  }

  /// 验证车牌号格式
  static bool isLicensePlate(String plate) {
    final plateRegex = RegExp(
      r'^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-Z][A-Z0-9]{4}[A-Z0-9挂学警港澳]$',
    );
    return plateRegex.hasMatch(plate);
  }
}

extension ValidatorsCheck on Validators {
  static bool hasError(String? msg) {
    return msg != null && msg.isNotEmpty;
  }

  /// 说明：
  /// 1. `Validators.checkPhoneNumber` 无法直接调用的原因是：
  ///    - `checkPhoneNumber` 是定义在 `extension Check on Validators` 扩展中的静态方法，
  ///      只能通过 `Check.checkPhoneNumber(...)` 或者 `Validators.checkPhoneNumber(...)`（Dart 2.15+ 支持静态扩展成员直接通过类型调用）。
  ///    - 但在 Dart 2.15 之前，静态扩展方法不能通过类型直接调用，只能通过扩展名调用。
  /// 2. 推荐做法：
  ///    - 如果 Dart 版本 >=2.15，可以直接 `Validators.checkPhoneNumber(...)`。
  ///    - 如果 Dart 版本 <2.15，需改为顶层静态方法或直接写在类中，或者通过扩展名 `Check.checkPhoneNumber(...)` 调用。
  ///
  /// 参考文档：
  /// https://dart.dev/language/extension-methods#static-members
  ///
  /// 建议：
  /// - 为了兼容性和可读性，建议将常用校验方法直接写在 `Validators` 类中作为静态方法。
  static String? checkPhoneNumber(String? phone, {BuildContext? context}) {
    String? msg;
    if (phone == null || phone.isEmpty) {
      msg = '手机号不能为空';
      // 手机号不能为空
      if (context != null && context.mounted) {
        unawaited(MyEasyPopMessage.showError(msg));
      }
      return msg;
    }
    if (!Validators.isPhoneNumber(phone)) {
      // 手机号格式不正确
      msg = '手机号格式不正确';
      if (context != null && context.mounted) {
        unawaited(MyEasyPopMessage.showError(msg));
      }
      return msg;
    }
    return msg;
  }

  /// 验证短信验证码格式,默认4位数字
  static String? checkSMSCode(String? smsCode, {BuildContext? context}) {
    String? msg;
    if (smsCode == null || smsCode.isEmpty) {
      msg = '验证码不能为空';
    } else if (!Validators.isSMSCode(smsCode)) {
      msg = '验证码格式不正确';
    }

    if (msg != null && msg.isNotEmpty && context != null && context.mounted) {
      MyEasyPopMessage.showError(msg);
    }
    return msg;
  }
}
