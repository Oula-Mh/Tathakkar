part of 'medications_bloc.dart';

enum MedicationsStatus { loading, ready, failure }

class MedicationsState extends Equatable {
  const MedicationsState({
    this.status = MedicationsStatus.loading,
    this.medications = const [],
    this.query = '',
    this.failureKey,
    this.actionFailureKey,
    this.deletedCount = 0,
  });

  final MedicationsStatus status;
  final List<Medication> medications;
  final String query;
  final String? failureKey;
  final String? actionFailureKey;
  final int deletedCount;

  List<Medication> get filtered => query.trim().isEmpty
      ? medications
      : medications.where((m) => m.name.toLowerCase().contains(query.trim().toLowerCase())).toList();

  int get outOfStockCount => medications.where((m) => m.isOutOfStock).length;
  int get lowStockCount => medications.where((m) => m.isLowStock).length;
  int get endedCount => medications.where((m) => m.isCourseEnded(DateTime.now())).length;

  Medication? byId(String id) {
    for (final m in medications) {
      if (m.id == id) return m;
    }
    return null;
  }

  MedicationsState copyWith({
    MedicationsStatus? status,
    List<Medication>? medications,
    String? query,
    String? failureKey,
    String? actionFailureKey,
    int? deletedCount,
  }) =>
      MedicationsState(
        status: status ?? this.status,
        medications: medications ?? this.medications,
        query: query ?? this.query,
        failureKey: failureKey,
        actionFailureKey: actionFailureKey,
        deletedCount: deletedCount ?? this.deletedCount,
      );

  @override
  List<Object?> get props =>
      [status, medications, query, failureKey, actionFailureKey, deletedCount];
}
