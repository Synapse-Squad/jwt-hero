import 'package:dio/dio.dart';

class RevokeTokenException extends DioException {
  RevokeTokenException({required super.requestOptions});
}
