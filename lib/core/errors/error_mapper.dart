import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/app_logger.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Single place that turns any thrown object into a [Failure].
abstract final class ErrorMapper {
  static Failure toFailure(Object error, [StackTrace? st]) {
    AppLogger.e('Mapped error: $error', error, st);
    return switch (error) {
      LinkException e => LinkFailure(e.messageKey),
      NotFoundException _ => const NotFoundFailure(),
      AppException e => ServerFailure(e.messageKey),
      FirebaseAuthException e => AuthFailure(_authKey(e.code)),
      FirebaseException e => _firebase(e),
      SocketException _ => const NetworkFailure(),
      TimeoutException _ => const NetworkFailure(),
      _ => const UnknownFailure(),
    };
  }

  static Failure _firebase(FirebaseException e) => switch (e.code) {
        'unavailable' || 'network-request-failed' || 'deadline-exceeded' =>
          const NetworkFailure(),
        'permission-denied' => const PermissionFailure(),
        'not-found' => const NotFoundFailure(),
        _ => const ServerFailure(),
      };

  static String _authKey(String code) => switch (code) {
        'invalid-email' => 'err_auth_invalid_email',
        'user-disabled' => 'err_auth_user_disabled',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'err_auth_invalid_credentials',
        'email-already-in-use' => 'err_auth_email_in_use',
        'weak-password' => 'err_auth_weak_password',
        'too-many-requests' => 'err_auth_too_many_requests',
        'network-request-failed' => 'err_network',
        'operation-not-allowed' => 'err_auth_not_allowed',
        _ => 'err_unknown',
      };
}

/// Wraps a data call and returns Either, so repositories stay tiny.
Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
  try {
    return Right(await action());
  } catch (e, st) {
    return Left(ErrorMapper.toFailure(e, st));
  }
}
