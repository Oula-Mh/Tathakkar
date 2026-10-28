/// Data-layer exceptions. Repositories convert them to [Failure]s.
class AppException implements Exception {
  const AppException(this.messageKey);
  final String messageKey;
  @override
  String toString() => 'AppException($messageKey)';
}

class NotFoundException extends AppException {
  const NotFoundException() : super('err_not_found');
}

class LinkException extends AppException {
  const LinkException(super.messageKey);
}
