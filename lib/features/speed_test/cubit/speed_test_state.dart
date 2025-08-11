import 'package:equatable/equatable.dart';

abstract class SpeedTestState extends Equatable {
  const SpeedTestState();
  @override
  List<Object> get props => [];
}

class SpeedTestInitial extends SpeedTestState {}
class SpeedTestLoading extends SpeedTestState {}
class SpeedTestError extends SpeedTestState {
  final String message;
  const SpeedTestError(this.message);
}