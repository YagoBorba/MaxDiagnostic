// lib/features/diagnostic/presentation/cubit/diagnostic_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

part 'diagnostic_state.dart';

class DiagnosticCubit extends Cubit<DiagnosticState> {
  // Irá depender do UseCase `RunDiagnosticTest`
  DiagnosticCubit() : super(DiagnosticState.initial());

  void startTest() {
    // Lógica para iniciar o teste virá aqui
    // TODO: Replace with proper logging
    emit(state.copyWith(globalStatus: GlobalTestStatus.running));
  }

  void webViewReady() {
    emit(state.copyWith(isWebViewReady: true));
  }
  
  // Outros métodos para lidar com eventos da webview virão aqui
}
