/// Base class for errors and failures in ADDA.
abstract class AppFailure implements Exception {
  final String message;
  final String? code;
  final bool retryable;

  const AppFailure(this.message, {this.code, this.retryable = false});

  @override
  String toString() =>
      '$runtimeType(code: $code, message: $message, retryable: $retryable)';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code, super.retryable = true});
}

class RoomFailure extends AppFailure {
  const RoomFailure(super.message, {super.code, super.retryable = false});
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.code, super.retryable = false});
}

class GameActionFailure extends AppFailure {
  const GameActionFailure(super.message, {super.code, super.retryable = false});
}
