part of 'reminder_health_bloc.dart';

class ReminderHealthState extends Equatable {
  const ReminderHealthState({this.health, this.loading = true, this.messageKey, this.messageSeq = 0});
  final ReminderHealth? health;
  final bool loading;

  /// One-shot feedback ("test scheduled", errors); [messageSeq] makes repeats distinct.
  final String? messageKey;
  final int messageSeq;

  /// True when the first check is done and something critical is missing.
  bool get needsAttention => health != null && !health!.isOk;

  ReminderHealthState copyWith({
    ReminderHealth? health,
    bool? loading,
    String? messageKey,
    int? messageSeq,
  }) =>
      ReminderHealthState(
        health: health ?? this.health,
        loading: loading ?? this.loading,
        messageKey: messageKey,
        messageSeq: messageSeq ?? this.messageSeq,
      );

  @override
  List<Object?> get props => [health, loading, messageKey, messageSeq];
}
