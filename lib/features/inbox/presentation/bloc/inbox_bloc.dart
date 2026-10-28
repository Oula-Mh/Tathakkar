import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/repositories/inbox_repository.dart';

part 'inbox_event.dart';
part 'inbox_state.dart';

class InboxBloc extends Bloc<InboxEvent, InboxState> {
  InboxBloc(this._repo) : super(const InboxState()) {
    on<InboxWatchRequested>((e, emit) {
      _sub?.cancel();
      _sub = _repo.watch(e.uid).listen((r) => add(InboxUpdated(r)));
    });
    on<InboxUpdated>((e, emit) => emit(e.result.fold(
          (f) => state.copyWith(loading: false, failureKey: f.messageKey),
          (items) => state.copyWith(loading: false, items: items),
        )));
  }

  final InboxRepository _repo;
  StreamSubscription<Either<Failure, List<InboxItem>>>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
