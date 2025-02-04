import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'jwt_token.dart';

extension TokenValidatorExt on JwtToken {
  bool get isValid {
    final decodedJwt = JWT.decode(accessToken);
    final expirationTimeEpoch = decodedJwt.payload['exp'];
    final expirationDateTime =
        DateTime.fromMillisecondsSinceEpoch(expirationTimeEpoch * 1000);

    return DateTime.now().isBefore(expirationDateTime);
  }
}
