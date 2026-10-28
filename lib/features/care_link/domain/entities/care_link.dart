import 'package:equatable/equatable.dart';

class CareLink extends Equatable {
  const CareLink({
    required this.elderUid,
    required this.elderName,
    required this.caregiverUid,
    required this.caregiverName,
  });
  final String elderUid;
  final String elderName;
  final String caregiverUid;
  final String caregiverName;

  @override
  List<Object?> get props => [elderUid, elderName, caregiverUid, caregiverName];
}

class LinkToken extends Equatable {
  const LinkToken({required this.token, required this.expiresAt});
  final String token;
  final DateTime expiresAt;

  static const scheme = 'tathakkar://link/';

  /// QR content: an opaque one-time token only (no health data, no password).
  String get qrData => '$scheme$token';

  static String? parseQr(String raw) {
    final v = raw.trim();
    if (!v.startsWith(scheme)) return null;
    final t = v.substring(scheme.length);
    return RegExp(r'^[A-Za-z0-9]{16,64}$').hasMatch(t) ? t : null;
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [token, expiresAt];
}
