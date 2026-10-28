import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/care_link.dart';
import '../../domain/usecases/care_link_usecases.dart';

part 'care_link_event.dart';
part 'care_link_state.dart';

class CareLinkBloc extends Bloc<CareLinkEvent, CareLinkState> {
  CareLinkBloc({
    required WatchMyCaregiver watchMyCaregiver,
    required CreateLinkToken createToken,
    required RedeemLinkToken redeemToken,
    required UnlinkCaregiver unlink,
  })  : _watch = watchMyCaregiver,
        _create = createToken,
        _redeem = redeemToken,
        _unlink = unlink,
        super(const CareLinkState()) {
    on<CareLinkWatchStarted>(_onStart);
    on<CareLinkUpdated>((e, emit) => e.result.fold(
          (_) {}, // keep last known state on stream errors
          (link) => emit(link == null
              ? state.copyWith(clearCaregiver: true)
              : state.copyWith(caregiver: link)),
        ));
    on<CareTokenRequested>(_onToken);
    on<CareQrScanned>(_onScanned);
    on<CareUnlinkRequested>(_onUnlink);
    on<CareResultCleared>((e, emit) => emit(state.copyWith(
          redeemOp: CareOp.idle,
          unlinkOp: CareOp.idle,
          tokenOp: CareOp.idle,
        )));
  }

  final WatchMyCaregiver _watch;
  final CreateLinkToken _create;
  final RedeemLinkToken _redeem;
  final UnlinkCaregiver _unlink;
  String _uid = '';
  String _name = '';
  StreamSubscription<Either<Failure, CareLink?>>? _sub;

  void _onStart(CareLinkWatchStarted e, Emitter<CareLinkState> emit) {
    _uid = e.uid;
    _name = e.name;
    _sub?.cancel();
    _sub = _watch(e.uid).listen((r) => add(CareLinkUpdated(r)));
  }

  Future<void> _onToken(CareTokenRequested e, Emitter<CareLinkState> emit) async {
    emit(state.copyWith(tokenOp: CareOp.working));
    final r = await _create((uid: _uid, name: _name));
    emit(r.fold(
      (f) => state.copyWith(tokenOp: CareOp.failure, failureKey: f.messageKey),
      (t) => state.copyWith(tokenOp: CareOp.success, token: t),
    ));
  }

  Future<void> _onScanned(CareQrScanned e, Emitter<CareLinkState> emit) async {
    if (state.redeemOp == CareOp.working) return;
    emit(state.copyWith(redeemOp: CareOp.working));
    final r = await _redeem(
        RedeemParams(rawQr: e.rawValue, caregiverUid: _uid, caregiverName: _name));
    emit(r.fold(
      (f) => state.copyWith(redeemOp: CareOp.failure, failureKey: f.messageKey),
      (link) => state.copyWith(redeemOp: CareOp.success, redeemedElderName: link.elderName),
    ));
  }

  Future<void> _onUnlink(CareUnlinkRequested e, Emitter<CareLinkState> emit) async {
    emit(state.copyWith(unlinkOp: CareOp.working));
    final r = await _unlink(_uid);
    emit(r.fold(
      (f) => state.copyWith(unlinkOp: CareOp.failure, failureKey: f.messageKey),
      (_) => state.copyWith(unlinkOp: CareOp.success, clearCaregiver: true),
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
