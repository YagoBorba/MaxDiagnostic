import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:maxt_diagnostic/features/known_networks/data/known_network_repository.dart';
import 'package:maxt_diagnostic/features/known_networks/domain/entities/known_network.dart';

part 'known_network_state.dart';

class KnownNetworkCubit extends Cubit<KnownNetworkState> {
  KnownNetworkCubit(this._repository) : super(KnownNetworkState.initial());

  final KnownNetworkRepository _repository;
  StreamSubscription<List<KnownNetwork>>? _subscription;

  void watchNetworks() {
    emit(state.copyWith(status: NetworkStatus.loading, error: null));
    _subscription?.cancel();
    _subscription = _repository.watchNetworks().listen(
      (networks) {
        emit(
          state.copyWith(
            status: NetworkStatus.loaded,
            networks: networks,
            error: null,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(
          state.copyWith(
            status: NetworkStatus.error,
            error: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> save(KnownNetwork network) async {
    try {
      await _repository.saveNetwork(network);
    } catch (error) {
      emit(
        state.copyWith(
          status: NetworkStatus.error,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> delete(String remoteId) async {
    try {
      await _repository.deleteNetwork(remoteId);
    } catch (error) {
      emit(
        state.copyWith(
          status: NetworkStatus.error,
          error: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
