import 'package:dio/dio.dart';

import '../jwt_hero.dart';
import 'jwt_token.dart';
import 'refresh_typedef.dart';
import 'revoke_token_exception.dart';

mixin JwtRefresherMixin {
  Future<JwtToken> refresh({
    required RequestOptions options,
    JwtToken? currentJwtToken,
    required Dio refreshClient,
    required TokenStorage tokenStorage,
    required Refresh onRefresh,
  }) async {
    if (currentJwtToken == null) {
      throw RevokeTokenException(requestOptions: options);
    }

    try {
      final newJwtToken = await onRefresh(
        refreshClient,
        currentJwtToken.refreshToken,
      );

      await tokenStorage.saveToken(newJwtToken);
      return newJwtToken;
    } on DioException catch (error) {
      if (error.response != null && error.response!.statusCode == 401) {
        await tokenStorage.clear();
        throw RevokeTokenException(requestOptions: options);
      } else {
        rethrow;
      }
    }
  }
}
