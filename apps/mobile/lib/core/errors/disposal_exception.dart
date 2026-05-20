/// User-facing disposal flow errors.
class DisposalException implements Exception {
  const DisposalException(this.message);

  final String message;

  @override
  String toString() => message;
}
