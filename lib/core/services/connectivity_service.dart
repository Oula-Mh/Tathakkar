import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService() : _c = Connectivity();
  final Connectivity _c;

  static bool _online(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);

  Future<bool> isOnline() async => _online(await _c.checkConnectivity());
  Stream<bool> get onChanged => _c.onConnectivityChanged.map(_online).distinct();
}
