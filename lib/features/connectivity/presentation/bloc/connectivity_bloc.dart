import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/connectivity_service.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc(this._service) : super(const ConnectivityState()) {
    on<ConnectivityStarted>((e, emit) async {
      emit(ConnectivityState(online: await _service.isOnline()));
      _sub?.cancel();
      _sub = _service.onChanged.listen((v) => add(ConnectivityChanged(v)));
    });
    on<ConnectivityChanged>((e, emit) => emit(ConnectivityState(online: e.online)));
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
