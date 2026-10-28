import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

/// Contract for every use case: one action, one result.
abstract interface class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

class NoParams {
  const NoParams();
}
