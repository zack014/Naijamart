import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijamart/core/errors.dart';

DioException _bad(int status, [Object? data]) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('uses the server detail message when present', () {
    final e = ApiException.from(_bad(409, {'detail': 'Only 2 left in stock.'}));
    expect(e.message, 'Only 2 left in stock.');
    expect(e.statusCode, 409);
  });

  test('reads FastAPI validation error lists', () {
    final e = ApiException.from(_bad(422, {
      'detail': [
        {'msg': 'value is not a valid email address'}
      ]
    }));
    expect(e.message, 'value is not a valid email address');
  });

  test('falls back to friendly text by status', () {
    expect(ApiException.from(_bad(500)).message, contains('servers'));
    expect(ApiException.from(_bad(401)).isUnauthorized, isTrue);
  });

  test('flags network failures', () {
    final e = ApiException.from(DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    ));
    expect(e.isNetwork, isTrue);
  });
}
