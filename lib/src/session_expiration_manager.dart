import 'dart:async';

enum SessionStatus { active, expired }

class SessionExpirationManager {
  final _sessionController = StreamController<SessionStatus>.broadcast()
    ..add(SessionStatus.active);
  Stream<SessionStatus> get sessionStatus => _sessionController.stream;

  /// should be called after login or register events
  /// if user successfully logged in or registered
  void startSession() => _sessionController.add(SessionStatus.active);

  void expireSession() => _sessionController.add(SessionStatus.expired);
}
