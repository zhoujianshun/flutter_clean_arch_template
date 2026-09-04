import 'package:flutter_clean_arch_template/core/network/log_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeHeaders', () {
    test('Authorization 头被遮罩，普通头保留', () {
      final result = LogSanitizer.sanitizeHeaders({
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig',
        'Content-Type': 'application/json',
      });

      expect(result['Authorization'].toString(), contains('***'));
      expect(result['Authorization'].toString(), isNot(contains('eyJhbGci')));
      expect(result['Content-Type'], 'application/json');
    });

    test('cookie / x-auth-token 大小写不敏感', () {
      final result = LogSanitizer.sanitizeHeaders({
        'COOKIE': 'session=abc123def456',
        'X-Auth-Token': 'tok_abcdef123456',
      });
      expect(result['COOKIE'].toString(), contains('***'));
      expect(result['X-Auth-Token'].toString(), contains('***'));
    });
  });

  group('sanitizeBody', () {
    test('顶层敏感字段脱敏', () {
      final result =
          LogSanitizer.sanitizeBody({
                'access_token': 'eyJhbGciOiJIUzI1NiJ9.payload.sig',
                'name': '张三',
              })
              as Map<String, dynamic>;

      expect(result['access_token'].toString(), contains('***'));
      expect(result['name'], '张三');
    });

    test('嵌套 Map / List 递归脱敏', () {
      final result =
          LogSanitizer.sanitizeBody({
                'user': {
                  'phone': '13812345678',
                  'profile': {'id_card': '320503199001011234'},
                },
                'orders': [
                  {'bank_account': '6222021234567890'},
                  {'order_id': 'A001'},
                ],
              })
              as Map<String, dynamic>;

      final user = result['user'] as Map<String, dynamic>;
      final profile = user['profile'] as Map<String, dynamic>;
      final orders = result['orders'] as List<dynamic>;

      expect(user['phone'].toString(), contains('***'));
      expect(profile['id_card'].toString(), contains('***'));
      expect(
        (orders[0] as Map<String, dynamic>)['bank_account'].toString(),
        contains('***'),
      );
      expect((orders[1] as Map<String, dynamic>)['order_id'], 'A001');
    });

    test('新增政务/实名类字段（mobile/idnumber/realname/address）', () {
      final result =
          LogSanitizer.sanitizeBody({
                'mobile': '13812345678',
                'idNumber': '320503199001011234',
                'real_name': '张三',
                'address': '苏州市姑苏区xx路1号',
              })
              as Map<String, dynamic>;

      expect(result['mobile'].toString(), contains('***'));
      expect(result['idNumber'].toString(), contains('***'));
      expect(result['real_name'].toString(), contains('***'));
      expect(result['address'].toString(), contains('***'));
    });

    test('短值（<=6 字符）完全遮罩为 ***，不泄漏任何字符', () {
      final result =
          LogSanitizer.sanitizeBody({
                'password': 'abc',
                'cvv': '1234',
              })
              as Map<String, dynamic>;

      expect(result['password'], '***');
      expect(result['cvv'], '***');
    });

    test('超过最大深度（10）时截断，不栈溢出', () {
      dynamic deep = {'leaf': 'value'};
      for (var i = 0; i < 50; i++) {
        deep = {'level$i': deep};
      }

      final result = LogSanitizer.sanitizeBody(deep) as Map<String, dynamic>;

      // 深度截断后应包含占位符，且不抛 StackOverflow
      expect(_deepContains(result, '<max-depth-reached>'), isTrue);
    });
  });

  group('generateRequestId', () {
    test('生成 8 位十六进制', () {
      final id = LogSanitizer.generateRequestId();
      expect(id, matches(RegExp(r'^[0-9a-f]{8}$')));
    });
  });
}

bool _deepContains(dynamic value, String marker) {
  if (value is Map) {
    for (final v in value.values) {
      if (_deepContains(v, marker)) return true;
    }
    return false;
  }
  if (value is List) {
    for (final v in value) {
      if (_deepContains(v, marker)) return true;
    }
    return false;
  }
  return value == marker;
}
