part of 'onboarding_bloc.dart';

class OnboardingState extends Equatable {
  const OnboardingState({this.page = 0});
  final int page;
  bool get isLast => page == OnboardingBloc.pageCount - 1;
  @override
  List<Object?> get props => [page];
}
