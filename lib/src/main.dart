import 'package:dio/dio.dart';
import 'package:jwt_hero/jwt_hero.dart';
import 'package:jwt_hero/src/jwt_token.dart';

void main() {
  final dio = Dio();

  dio.interceptors.add(
    JwtHeroInterceptor(
      tokenStorage: SecureTokenStorage(),
      baseClient: dio,
      onRefresh: (refreshClient, refreshToken) async {
        refreshClient.options = refreshClient.options.copyWith(
          headers: {'refresh-Token': refreshToken},
        );

        final response = await refreshClient.post('/refresh');

        return JwtToken(
          accessToken: response.data['accessToken'],
          refreshToken: response.data['refreshToken'],
        );
      },
      sessionManager: SessionExpirationManager(),
    ),
  );
}
