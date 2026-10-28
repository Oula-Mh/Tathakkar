import 'package:equatable/equatable.dart';

/// Stored states. "Upcoming/due/unconfirmed" are derived at display time.
enum DoseStatus { pending, taken, missed }

class DoseLog extends Equatable {
  const DoseLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledAt,
    required this.status,
    this.actedAt,
    this.amount = 1,
  });

  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledAt;
  final DoseStatus status;
  final DateTime? actedAt;
  final int amount;

  @override
  List<Object?> get props =>
      [id, medicationId, medicationName, scheduledAt, status, actedAt, amount];
}

/// Deterministic id => confirming twice can never double-deduct stock.
String doseLogId(String medicationId, DateTime scheduledAt) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${medicationId}_${scheduledAt.year}${p(scheduledAt.month)}${p(scheduledAt.day)}'
      '${p(scheduledAt.hour)}${p(scheduledAt.minute)}';
}
