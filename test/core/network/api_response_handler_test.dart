import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_clean_arch_template/core/errors/failures.dart';
import 'package:flutter_clean_arch_template/core/network/api_response_handler.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(
  dynamic data, {
  int statusCode = 200,
}) {
  return Response<dynamic>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: '/test'),
  );
}

Map<String, String> _identityJson(Map<String, dynamic> json) =>
    json.map((k, v) => MapEntry(k, v.toString()));

void main() {
  group('handleObjectResponse', () {
    test('成功响应返回解析对象', () {
      ApiResponseHandler.handleObjectResponse<Map<String, String>>(
        _response({'code': 200, 'msg': 'ok', 'data': {'id': '1'}}),
        _identityJson,
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r['id'], '1'),
      );
    });

    test('业务失败码映射为 Left', () {
      final result = ApiResponseHandler.handleObjectResponse<Map<String, String>>(
        _response({'code': 500, 'msg': '服务错误', 'data': null}),
        _identityJson,
      );

      expect(result, isA<Left<Failure, Map<String, String>>>());
    });

    test('code 为字符串 "200" 容错解析为成功', () {
      final result = ApiResponseHandler.handleObjectResponse<Map<String, String>>(
        _response({'code': '200', 'msg': 'ok', 'data': {'id': '1'}}),
        _identityJson,
      );

      expect(result.isRight(), isTrue);
    });

    test('响应体为 null 返回 ServerFailure', () {
      final result = ApiResponseHandler.handleObjectResponse<Map<String, String>>(
        _response(null),
        _identityJson,
      );

      expect(result, isA<Left<Failure, Map<String, String>>>());
    });

    test('fromJson 抛异常时返回解析失败', () {
      Map<String, String> badFromJson(Map<String, dynamic> json) {
        throw const FormatException('bad json');
      }

      final result = ApiResponseHandler.handleObjectResponse<Map<String, String>>(
        _response({'code': 200, 'msg': 'ok', 'data': {'id': '1'}}),
        badFromJson,
      );

      expect(result, isA<Left<Failure, Map<String, String>>>());
    });
  });

  group('handleListResponse', () {
    test('成功响应返回列表', () {
      ApiResponseHandler.handleListResponse<Map<String, String>>(
        _response({
          'code': 200,
          'msg': 'ok',
          'data': [
            {'id': '1'},
            {'id': '2'},
          ],
        }),
        _identityJson,
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, hasLength(2)),
      );
    });

    test('data 为空列表时返回空列表', () {
      ApiResponseHandler.handleListResponse<Map<String, String>>(
        _response({
          'code': 200,
          'msg': 'ok',
          'data': <dynamic>[],
        }),
        _identityJson,
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, isEmpty),
      );
    });
  });

  group('handleVoidResponse', () {
    test('业务成功返回 Right(null)', () {
      final result = ApiResponseHandler.handleVoidResponse(
        _response({'code': 200, 'msg': 'ok'}),
      );

      expect(result.isRight(), isTrue);
    });

    test('data 为 null 且 HTTP 2xx 视为成功', () {
      final result = ApiResponseHandler.handleVoidResponse(
        _response(null, statusCode: 204),
      );

      expect(result.isRight(), isTrue);
    });

    test('业务失败码返回 Left', () {
      final result = ApiResponseHandler.handleVoidResponse(
        _response({'code': 401, 'msg': 'unauthorized'}),
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('handleBooleanResponse', () {
    test('显式 true 透传', () {
      ApiResponseHandler.handleBooleanResponse(
        _response({'code': 200, 'msg': 'ok', 'data': true}),
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, isTrue),
      );
    });

    test('data 缺省默认 true', () {
      ApiResponseHandler.handleBooleanResponse(
        _response({'code': 200, 'msg': 'ok'}),
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, isTrue),
      );
    });
  });

  group('handleStringResponse', () {
    test('data 为 String 直接返回', () {
      ApiResponseHandler.handleStringResponse(
        _response({'code': 200, 'msg': 'ok', 'data': 'abc123'}),
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, 'abc123'),
      );
    });

    test('data 为 Map 时按 dataKey 提取', () {
      ApiResponseHandler.handleStringResponse(
        _response({
          'code': 200,
          'msg': 'ok',
          'data': {'token': 'tk_999'},
        }),
        dataKey: 'token',
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, 'tk_999'),
      );
    });
  });

  group('handleIntResponse', () {
    test('int 值直接返回', () {
      ApiResponseHandler.handleIntResponse(
        _response({'code': 200, 'msg': 'ok', 'data': 42}),
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, 42),
      );
    });

    test('字符串数字容错解析', () {
      ApiResponseHandler.handleIntResponse(
        _response({'code': 200, 'msg': 'ok', 'data': '42'}),
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, 42),
      );
    });

    test('Map 按 dataKey 提取', () {
      ApiResponseHandler.handleIntResponse(
        _response({
          'code': 200,
          'msg': 'ok',
          'data': {'count': 7},
        }),
        dataKey: 'count',
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r, 7),
      );
    });

    test('无法解析的类型返回失败', () {
      final result = ApiResponseHandler.handleIntResponse(
        _response({'code': 200, 'msg': 'ok', 'data': true}),
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('handlePageableResponse', () {
    test('标准分页包裹解析', () {
      ApiResponseHandler.handlePageableResponse<Map<String, String>>(
        _response({
          'code': 200,
          'msg': 'ok',
          'data': {
            'rows': [
              {'id': '1'},
            ],
            'total': 1,
            'hasNext': false,
          },
        }),
        _identityJson,
      ).fold(
        (l) => fail('should be right: $l'),
        (r) {
          expect(r.total, 1);
          expect(r.rows, hasLength(1));
          expect(r.hasNext, isFalse);
        },
      );
    });

    test('顶层分页字段嗅探（rows/total 直接在顶层）', () {
      ApiResponseHandler.handlePageableResponse<Map<String, String>>(
        _response({
          'code': 200,
          'msg': 'ok',
          'rows': [
            {'id': '1'},
          ],
          'total': 5,
        }),
        _identityJson,
      ).fold(
        (l) => fail('should be right: $l'),
        (r) => expect(r.total, 5),
      );
    });
  });
}
