import 'package:bloc/bloc.dart';
import 'speed_test_state.dart';

class SpeedTestCubit extends Cubit<SpeedTestState> {
  SpeedTestCubit() : super(SpeedTestInitial());

  void startTest() {
    emit(SpeedTestLoading());
    Future.delayed(const Duration(seconds: 2), () {
      emit(const SpeedTestError("Função de teste ainda não implementada."));
    });
  }
}