import 'package:equatable/equatable.dart';

/// Domain-level auth failure surfaced to the presentation layer.
class AuthException extends Equatable implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthException: $message';
}
