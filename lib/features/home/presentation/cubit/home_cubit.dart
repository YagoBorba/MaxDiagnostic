import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future<void> fetchInitialInfo() async {
    emit(HomeLoading());
    
    // Simulação temporária de dados enquanto configuramos as dependências
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock network info for testing
    const networkInfo = NetworkInfoEntity(
      connectionType: 'WiFi',
      wifiName: 'Borba',
      wifiSignalStrength: -45,
      wifiFrequency: '5 GHz',
      externalIP: '192.168.1.100',
      internalIP: '10.0.0.1',
    );
    
    emit(const HomeLoaded(networkInfo: networkInfo));
  }
}
