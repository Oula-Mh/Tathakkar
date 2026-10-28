part of 'connectivity_bloc.dart';

sealed class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  @override
  List<Object?> get props => [];
}

class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

class ConnectivityChanged extends ConnectivityEvent {
  const ConnectivityChanged(this.online);
  final bool online;
  @override
  List<Object?> get props => [online];
}
