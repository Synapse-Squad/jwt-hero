import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'jwt_token.dart';
import 'token_storage.dart';

enum _TokenKey {
  accessToken('accessToken'),
  refreshToken('refreshToken');

  const _TokenKey(this.key);

  final String key;
}

/// {@template secure_token_storage}
/// A secure implementation of [TokenStorage] that uses [FlutterSecureStorage].
/// {@endtemplate}
final class SecureTokenStorage implements TokenStorage {
  /// {@macro secure_token_storage}
  const SecureTokenStorage(this.secureStorage);

  /// The secure storage to store the JWT token.
  final FlutterSecureStorage secureStorage;

  @override
  Future<JwtToken?> loadToken() async {
    final accessToken = await secureStorage.read(
      key: _TokenKey.accessToken.key,
    );
    final refreshToken = await secureStorage.read(
      key: _TokenKey.refreshToken.key,
    );

    if (accessToken != null && refreshToken != null) {
      return JwtToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    return null;
  }

  @override
  Future<void> saveToken(JwtToken jwtToken) async {
    await secureStorage.write(
      key: _TokenKey.accessToken.key,
      value: jwtToken.accessToken,
    );

    await secureStorage.write(
      key: _TokenKey.refreshToken.key,
      value: jwtToken.refreshToken,
    );
  }

  @override
  Future<void> clear() async {
    await secureStorage.delete(key: _TokenKey.accessToken.key);
    await secureStorage.delete(key: _TokenKey.refreshToken.key);
  }

  @override
  Future<String?> get accessToken =>
      secureStorage.read(key: _TokenKey.accessToken.key);

  @override
  Future<String?> get refreshToken =>
      secureStorage.read(key: _TokenKey.refreshToken.key);
}
