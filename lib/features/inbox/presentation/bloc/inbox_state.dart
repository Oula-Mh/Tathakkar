part of 'inbox_bloc.dart';

class InboxState extends Equatable {
  const InboxState({this.items = const [], this.loading = true, this.failureKey});
  final List<InboxItem> items;
  final bool loading;
  final String? failureKey;

  InboxState copyWith({List<InboxItem>? items, bool? loading, String? failureKey}) => InboxState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        failureKey: failureKey,
      );

  @override
  List<Object?> get props => [items, loading, failureKey];
}
