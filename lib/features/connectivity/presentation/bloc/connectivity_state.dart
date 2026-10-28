part of 'connectivity_bloc.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState({this.online = true});
  final bool online;
  @override
  List<Object?> get props => [online];
}
