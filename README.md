# JWT Hero

JWT Hero is a Dart package that provides an easy way to handle JWT token management, including token validation, refresh, and retrying failed requests. This package is designed to work seamlessly with the Dio HTTP client.

## Installation

Add `jwt_hero` to your `pubspec.yaml` file:

```yaml
dependencies:
  jwt_hero: ^0.1.0
```

Then, run flutter pub get to install the package.

## Setting Up

To use **JwtHeroInterceptor**, you need to set up a few components:

- Token Storage: Implement the TokenStorage interface to define how tokens are stored and retrieved.
- Refresh Logic: Provide a callback to handle token refresh logic.
- Session Management: Optionally, manage session expiration.

### Example

Here is a complete example of how to set up and use **JwtHeroInterceptor**.
As a first step, you need to implement the **TokenStorage** interface:

```dart
enum _TokenKey {
  accessToken('accessToken'),
  refreshToken('refreshToken');

  const _TokenKey(this.key);

  final String key;
}

final class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this.secureStorage);

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
```

> **Note:** In by default, package has its own **TokenStorage** implementation.

Next, you need to provide a callback to handle token refresh logic and
create an instance of **JwtHeroInterceptor**:

```dart
  final dio = Dio();

  dio.interceptors.add(
    JwtHeroInterceptor(
      tokenStorage: SecureTokenStorage(), // optional 
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
```

### SessionManager

You can inject **SessionManager** to your classes using Dependency Injection (DI) 
to listen **sessionStatus**. And if user login/register successfully, we should call 
**sessionManager.startSession()** to start the session.

### Handling Token Expiration
The JWTHeroInterceptor automatically handles token expiration and refresh. If a request fails with a 401 status code, the interceptor will attempt to refresh the token and retry the request.

----

## Maintainers

- [Thisisyusub](https://github.com/thisisyusub)