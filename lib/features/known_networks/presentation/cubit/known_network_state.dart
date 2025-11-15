part of 'known_network_cubit.dart';

enum NetworkStatus { initial, loading, loaded, error }

class KnownNetworkState extends Equatable {
  const KnownNetworkState({
    required this.status,
    required this.networks,
    required this.error,
  });

  factory KnownNetworkState.initial() => const KnownNetworkState(
        status: NetworkStatus.initial,
        networks: [],
        error: null,
      );

  final NetworkStatus status;
  final List<KnownNetwork> networks;
  final String? error;

  KnownNetworkState copyWith({
    NetworkStatus? status,
    List<KnownNetwork>? networks,
    String? error,
  }) {
    return KnownNetworkState(
      status: status ?? this.status,
      networks: networks ?? this.networks,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, networks, error];
}
