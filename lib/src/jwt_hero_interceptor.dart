import 'package:dio/dio.dart';

import '../jwt_hero.dart';
import 'jwt_refresher_mixin.dart';
import 'refresh_typedef.dart';
import 'request_retry_mixin.dart';
import 'revoke_token_exception.dart';
import 'session_expiration_manager.dart';
import 'token_validator_ext.dart';

class JwtHeroInterceptor extends QueuedInterceptor
    with JwtRefresherMixin, RequestRetryMixin {
  JwtHeroInterceptor({
    required this.tokenStorage,
    required this.baseClient,
    required this.onRefresh,
    required this.sessionManager,
  }) {
    refreshClient = Dio();
    refreshClient.options = BaseOptions(baseUrl: baseClient.options.baseUrl);

    retryClient = Dio();
    retryClient.options = BaseOptions(baseUrl: baseClient.options.baseUrl);
  }

  final TokenStorage tokenStorage;
  final Dio baseClient;
  late final Dio refreshClient;
  late final Dio retryClient;
  final Refresh onRefresh;
  final SessionExpirationManager sessionManager;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final jwtToken = await tokenStorage.loadToken();

      if (jwtToken == null) {
        return handler.next(options);
      }

      if (jwtToken.isValid) {
        options.headers.addAll(await _buildHeaders());
        return handler.next(options);
      } else {
        await refresh(
          options: options,
          currentJwtToken: jwtToken,
          refreshClient: refreshClient,
          tokenStorage: tokenStorage,
          onRefresh: onRefresh,
        );

        options.headers.addAll(await _buildHeaders());
        return handler.next(options);
      }
    } on DioException catch (error) {
      if (error.response != null && error.response!.statusCode == 401) {
        return handler.reject(
          RevokeTokenException(requestOptions: options),
          true,
        );
      }

      return handler.reject(error);
    } catch (error) {
      return handler.next(options);
    }
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err is RevokeTokenException) {
      sessionManager.expireSession();
      return handler.reject(err);
    }

    if (!shouldRefresh(err.response)) {
      return handler.next(err);
    }

    final jwtToken = await tokenStorage.loadToken();

    if (jwtToken == null) {
      return handler.reject(err);
    }

    try {
      if (jwtToken.isValid) {
        final previousRequest = await retry(
          retryClient: retryClient,
          requestOptions: err.requestOptions,
          buildHeaders: _buildHeaders,
        );

        return handler.resolve(previousRequest);
      } else {
        await refresh(
          options: err.requestOptions,
          currentJwtToken: jwtToken,
          refreshClient: refreshClient,
          tokenStorage: tokenStorage,
          onRefresh: onRefresh,
        );

        final previousRequest = await retry(
          retryClient: retryClient,
          requestOptions: err.requestOptions,
          buildHeaders: _buildHeaders,
        );
        return handler.resolve(previousRequest);
      }
    } on RevokeTokenException {
      sessionManager.expireSession();
      return handler.reject(err);
    } on DioException catch (err) {
      return handler.next(err);
    }
  }

  Future<Map<String, dynamic>> _buildHeaders() async {
    final jwtToken = await tokenStorage.loadToken();

    return {
      'Authorization': 'Bearer ${jwtToken!.accessToken}',
    };
  }

  bool shouldRefresh<R>(Response<R>? response) => response?.statusCode == 401;
}
