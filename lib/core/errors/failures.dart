import 'package:equatable/equatable.dart';

/// Domain-level errors. [messageKey] is a localization key (never raw text),
/// so the presentation layer can show the right language.
sealed class Failure extends Equatable {
  const Failure(this.messageKey);
  final String messageKey;

  @override
  List<Object?> get props => [messageKey];
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('err_network');
}

class ServerFailure extends Failure {
  const ServerFailure([super.messageKey = 'err_server']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.messageKey);
}

class PermissionFailure extends Failure {
  const PermissionFailure() : super('err_permission');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure() : super('err_not_found');
}

class CacheFailure extends Failure {
  const CacheFailure() : super('err_cache');
}

class LinkFailure extends Failure {
  const LinkFailure(super.messageKey);
}

class UnknownFailure extends Failure {
  const UnknownFailure() : super('err_unknown');
}
