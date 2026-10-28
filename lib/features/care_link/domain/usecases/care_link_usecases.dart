import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/care_link.dart';
import '../repositories/care_link_repository.dart';

class WatchMyCaregiver {
  const WatchMyCaregiver(this._repo);
  final CareLinkRepository _repo;
  Stream<Either<Failure, CareLink?>> call(String uid) => _repo.watchMyCaregiver(uid);
}

class CreateLinkToken implements UseCase<LinkToken, ({String uid, String name})> {
  const CreateLinkToken(this._repo);
  final CareLinkRepository _repo;
  @override
  Future<Either<Failure, LinkToken>> call(({String uid, String name}) p) =>
      _repo.createToken(uid: p.uid, name: p.name);
}

class RedeemParams extends Equatable {
  const RedeemParams({required this.rawQr, required this.caregiverUid, required this.caregiverName});
  final String rawQr;
  final String caregiverUid;
  final String caregiverName;
  @override
  List<Object?> get props => [rawQr, caregiverUid, caregiverName];
}

class RedeemLinkToken implements UseCase<CareLink, RedeemParams> {
  const RedeemLinkToken(this._repo);
  final CareLinkRepository _repo;
  @override
  Future<Either<Failure, CareLink>> call(RedeemParams p) {
    final token = LinkToken.parseQr(p.rawQr);
    if (token == null) return Future.value(const Left(LinkFailure('err_link_invalid')));
    return _repo.redeem(token: token, caregiverUid: p.caregiverUid, caregiverName: p.caregiverName);
  }
}

class UnlinkCaregiver implements UseCase<Unit, String> {
  const UnlinkCaregiver(this._repo);
  final CareLinkRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(String elderUid) => _repo.unlink(elderUid);
}
