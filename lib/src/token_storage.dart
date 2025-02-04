import 'jwt_token.dart';

/// The interface for token storage.
///
/// This interface is used by the [AuthInterceptor]
/// to store and retrieve the Auth token pair.
abstract interface class TokenStorage {
  /// Load the Auth token pair.
  Future<JwtToken?> loadToken();

  /// Save the Auth token pair.
  Future<void> saveToken(JwtToken token);

  /// Clear the Auth token pair.
  ///
  /// This is used to clear the token pair when the request fails with a 401.
  Future<void> clear();

  /// A stream of token pairs.
  Stream<JwtToken?> getTokenStream();

  /// Close the token storage.
  Future<void> close();

  /// access token from token storage
  Future<String?> get accessToken;

  /// refresh token from token storage
  Future<String?> get refreshToken;
}
