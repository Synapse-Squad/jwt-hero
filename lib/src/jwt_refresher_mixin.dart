import 'package:dio/dio.dart';

import '../jwt_hero.dart';
import 'jwt_token.dart';
import 'refresh_typedef.dart';
import 'revoke_token_exception.dart';

/// A mixin responsible for refreshing JWT tokens.
///
/// This mixin provides the functionality to refresh JWT tokens when they
/// expire. It defines a method to handle the token refresh process, which
/// includes making a request to the refresh endpoint, updating the token
/// storage, and handling any errors that occur during the refresh process.
///
/// The mixin is intended to be used with classes that manage HTTP requests
/// and need to handle JWT token expiration and refresh automatically.

mixin JwtRefresherMixin {

  /// Refreshes the JWT token. 
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
