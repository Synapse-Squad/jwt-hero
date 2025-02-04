import 'package:dio/dio.dart';

import 'jwt_token.dart';

typedef Refresh = Future<JwtToken> Function(
  Dio refreshClient,
  String refreshToken,
);
