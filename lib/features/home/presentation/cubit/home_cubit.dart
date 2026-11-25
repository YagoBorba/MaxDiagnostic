import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/core/usecases/usecase.dart';
import 'package:maxt_diagnostic/core/config/app_config.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maxt_diagnostic/domain/usecases/get_initial_network_info.dart';
import 'package:maxt_diagnostic/domain/usecases/check_server_reachability.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetInitialNetworkInfo getInitialNetworkInfo;
  final CheckServerReachability checkServerReachability;
  final AppConfig config;
  Timer? _refreshTimer;
  bool _isFetching = false;

  HomeCubit({
    required this.getInitialNetworkInfo, 
    required this.config,
    required this.checkServerReachability,
  }) : super(const HomeInitial());

  Future<void> fetchInitialInfo() async {
    if (_isFetching) return;
    _isFetching = true;
    final isFirstLoad = state is HomeInitial ||
        state is HomeError ||
        state is HomePermissionDenied;
    if (isFirstLoad) emit(const HomeLoading());
    
    final reachabilityFuture = checkServerReachability(const NoParams());
    final networkInfoFuture = getInitialNetworkInfo(const NoParams());

    final results = await Future.wait([networkInfoFuture, reachabilityFuture]);

    final networkResult = results[0] as Either<Failure, NetworkInfoEntity>;
    final reachabilityResult = results[1] as Either<Failure, bool>;

    final isReachable = reachabilityResult.fold((l) => false, (r) => r);

    networkResult.fold(
      (failure) {
        if (failure is PermissionFailure) {
          emit(const HomePermissionDenied(
              message:
                  'Permissão de localização negada. Habilite para ler informações do Wi‑Fi.'));
        } else {
          emit(HomeError(message: _mapFailure(failure)));
        }
      },
      (info) {
        emit(HomeLoaded(
          networkInfo: info,
          isSpeedTestServerReachable: isReachable,
        ));
      },
    );
    _isFetching = false;
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      await fetchInitialInfo();
      return;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    final req = await Permission.locationWhenInUse.request();
    if (req.isGranted) {
      await fetchInitialInfo();
    } else if (req.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      emit(const HomePermissionDenied(
          message: 'Permissão de localização negada.'));
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

  String _mapFailure(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Sem conexão de rede disponível.';
    }
    if (failure is DeviceInfoFailure) {
      return 'Falha ao coletar informações do dispositivo.';
    }
    if (failure is CacheFailure) {
      return 'Falha ao acessar o cache local.';
    }
    if (failure is ServerFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Erro inesperado no servidor.';
    }
    return failure.message.isNotEmpty ? failure.message : 'Ocorreu um erro inesperado.';
  }
}
