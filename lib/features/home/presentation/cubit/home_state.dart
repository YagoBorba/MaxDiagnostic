// lib/features/home/presentation/cubit/home_state.dart
part of 'home_cubit.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final NetworkInfoEntity networkInfo;

  const HomeLoaded({required this.networkInfo});

  @override
  List<Object> get props => [networkInfo];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}

class HomePermissionDenied extends HomeState {
  final String message;

  const HomePermissionDenied({required this.message});

  @override
  List<Object> get props => [message];
}
