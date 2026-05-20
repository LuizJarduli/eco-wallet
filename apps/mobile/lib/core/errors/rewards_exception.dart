/// User-facing rewards flow errors.
class RewardsException implements Exception {
  const RewardsException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
