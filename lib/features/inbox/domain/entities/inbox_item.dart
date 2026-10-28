import 'package:equatable/equatable.dart';

enum InboxType { missedDose, lowStock, outOfStock }

/// Caregiver notification written by Cloud Functions; text is built locally
/// from these fields so it follows the user's language.
class InboxItem extends Equatable {
  const InboxItem({
    required this.id,
    required this.type,
    required this.personName,
    required this.medicationName,
    required this.createdAt,
    this.scheduledAt,
    this.remaining,
    this.threshold,
    this.amount,
  });

  final String id;
  final InboxType type;
  final String personName;
  final String medicationName;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final int? remaining;
  final int? threshold;
  final int? amount;

  @override
  List<Object?> get props =>
      [id, type, personName, medicationName, createdAt, scheduledAt, remaining, threshold, amount];
}
