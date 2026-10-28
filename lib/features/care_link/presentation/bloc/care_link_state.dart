part of 'care_link_bloc.dart';

enum CareOp { idle, working, success, failure }

class CareLinkState extends Equatable {
  const CareLinkState({
    this.caregiver,
    this.token,
    this.tokenOp = CareOp.idle,
    this.redeemOp = CareOp.idle,
    this.redeemedElderName,
    this.unlinkOp = CareOp.idle,
    this.failureKey,
  });

  /// My caregiver (when I am the elder).
  final CareLink? caregiver;
  final LinkToken? token;
  final CareOp tokenOp;
  final CareOp redeemOp;
  final String? redeemedElderName;
  final CareOp unlinkOp;
  final String? failureKey;

  CareLinkState copyWith({
    CareLink? caregiver,
    bool clearCaregiver = false,
    LinkToken? token,
    CareOp? tokenOp,
    CareOp? redeemOp,
    String? redeemedElderName,
    CareOp? unlinkOp,
    String? failureKey,
  }) =>
      CareLinkState(
        caregiver: clearCaregiver ? null : (caregiver ?? this.caregiver),
        token: token ?? this.token,
        tokenOp: tokenOp ?? this.tokenOp,
        redeemOp: redeemOp ?? this.redeemOp,
        redeemedElderName: redeemedElderName ?? this.redeemedElderName,
        unlinkOp: unlinkOp ?? this.unlinkOp,
        failureKey: failureKey,
      );

  @override
  List<Object?> get props =>
      [caregiver, token, tokenOp, redeemOp, redeemedElderName, unlinkOp, failureKey];
}
