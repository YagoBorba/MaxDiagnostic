import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maxt_diagnostic/domain/usecases/get_initial_network_info.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetInitialNetworkInfo getInitialNetworkInfo;
  final AppConfig config;
  Timer? _refreshTimer;
  bool _isFetching = false;

  HomeCubit({required this.getInitialNetworkInfo, required this.config}) : super(HomeInitial());

  Future<void> fetchInitialInfo() async {
    if (_isFetching) return;
    _isFetching = true;
    final isFirstLoad = state is HomeInitial || state is HomeError || state is HomePermissionDenied;
    if (isFirstLoad) emit(HomeLoading());
    final result = await getInitialNetworkInfo(const NoParams());
    result.fold(
      (failure) {
        final msg = _mapFailure(failure);
        if (msg.toLowerCase().contains('permissionfailure') || msg.toLowerCase().contains('permission')) {
          emit(HomePermissionDenied(message: 'Permissão de localização negada. Habilite para ler informações do Wi‑Fi.'));
        } else {
          emit(HomeError(message: msg));
        }
      },
      (info) {
        // Usa AppConfig para decidir se o teste pode ser iniciado
        emit(HomeLoaded(networkInfo: info));
      },
    );
    _isFetching = false;
  }

  Future<void> requestLocationPermission() async {
    // Se já está concedida, apenas refaz a busca
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      await fetchInitialInfo();
      return;
    }

    // Se estiver permanentemente negada, abrir configurações
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    // Solicitar novamente
    final req = await Permission.locationWhenInUse.request();
    if (req.isGranted) {
      await fetchInitialInfo();
    } else if (req.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      emit(const HomePermissionDenied(message: 'Permissão de localização negada.'));
    }
  }

  void startAutoRefresh({Duration? interval}) {
    if (_refreshTimer != null) return;
    _refreshTimer = Timer.periodic(interval ?? config.homeRefreshInterval, (_) {
      fetchInitialInfo();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  String _mapFailure(Object failure) {
    return failure.toString().replaceAll('Instance of ', '').replaceAll('(', ': ').replaceAll(')', '');
  }
}
