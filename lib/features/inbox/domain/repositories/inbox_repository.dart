import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inbox_item.dart';

abstract interface class InboxRepository {
  Stream<Either<Failure, List<InboxItem>>> watch(String uid);
}
