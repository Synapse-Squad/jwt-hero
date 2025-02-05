import 'package:dio/dio.dart';

import '../jwt_hero.dart';
import 'jwt_refresher_mixin.dart';
import 'refresh_typedef.dart';
import 'request_retry_mixin.dart';
import 'revoke_token_exception.dart';
import 'token_validator_ext.dart';

/// Intercepts HTTP requests to handle JWT token management.
///
/// This interceptor is responsible for adding JWT tokens to request headers,
/// refreshing expired tokens, and retrying requests with new tokens if needed.
/// It uses the provided token storage to load and validate tokens, and the
/// session manager to handle session expiration.
///
/// The interceptor also initializes separate clients for refreshing tokens
/// and retrying requests.
///
/// Mixins:
/// - [JwtRefresherMixin]: Provides functionality to refresh JWT tokens.
/// - [RequestRetryMixin]: Provides functionality to retry requests.

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

  /// The storage to load and save the JWT token.
  final TokenStorage tokenStorage;

  /// The base client to make requests.
  final Dio baseClient;

  /// The client to make requests to refresh the JWT token.
  late final Dio refreshClient;

  /// The client to retry the request after refreshing the JWT token.
  late final Dio retryClient;

  /// The function to refresh the JWT token.
  final Refresh onRefresh;

  /// The session manager to expire the session.
  final SessionExpirationManager sessionManager;

  /// Adds JWT token to request headers if valid and refreshes it if needed 
  /// before making the request.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      /// Load the JWT token from the storage.
      final jwtToken = await tokenStorage.loadToken();

      /// If the JWT token is null, continue with the request.
      if (jwtToken == null) {
        return handler.next(options);
      }

      /// If the JWT token is valid, add it to the request headers and continue
      /// with the request.
      if (jwtToken.isValid) {
        options.headers.addAll(await _buildHeaders());
        return handler.next(options);
      }

      /// If the JWT token is not valid, refresh it and add it to the request
      /// headers.
      else {
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

  /// Handles JWT token errors and attempts to refresh the token before retrying
  /// the request.

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    /// If the error is a RevokeTokenException, expire the session and reject
    /// the request.
    if (err is RevokeTokenException) {
      sessionManager.expireSession();
      return handler.reject(err);
    }

    /// If the response status code is not 401, continue with the error.
    if (!shouldRefresh(err.response)) {
      return handler.next(err);
    }

    /// Load the JWT token from the storage.
    final jwtToken = await tokenStorage.loadToken();

    /// If the JWT token is null, reject the request.
    if (jwtToken == null) {
      return handler.reject(err);
    }

    /// If the JWT token is valid, retry the request.
    try {
      if (jwtToken.isValid) {
        final previousRequest = await retry(
          retryClient: retryClient,
          requestOptions: err.requestOptions,
          buildHeaders: _buildHeaders,
        );

        return handler.resolve(previousRequest);
      }

      /// If the JWT token is not valid, refresh it and retry the request.
      else {
        await refresh(
          options: err.requestOptions,
          currentJwtToken: jwtToken,
          refreshClient: refreshClient,
          tokenStorage: tokenStorage,
          onRefresh: onRefresh,
        );

        /// Retry the request.
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

  /// Builds the headers with the JWT token.
  Future<Map<String, dynamic>> _buildHeaders() async {
    final jwtToken = await tokenStorage.loadToken();

    return {
      'Authorization': 'Bearer ${jwtToken!.accessToken}',
    };
  }

  /// Checks if the response should be refreshed.
  bool shouldRefresh<R>(Response<R>? response) => response?.statusCode == 401;
}
