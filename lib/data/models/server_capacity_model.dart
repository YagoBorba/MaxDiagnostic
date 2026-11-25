import 'package:equatable/equatable.dart';

class ServerCapacityModel extends Equatable {
  final String status;

  final int slotsAvailable;

  final int estimatedWaitSeconds;

  final String? token;

  const ServerCapacityModel({
    required this.status,
    this.slotsAvailable = 0,
    this.estimatedWaitSeconds = 0,
    this.token,
  });

  factory ServerCapacityModel.fromJson(Map<String, dynamic> json) {
    return ServerCapacityModel(
      status: json['status'] as String,
      slotsAvailable: (json['slots_available'] as int?) ?? 0,
      estimatedWaitSeconds: (json['estimated_wait_seconds'] as int?) ?? 0,
      token: json['token'] as String?,
    );
  }

  factory ServerCapacityModel.error() {
    return const ServerCapacityModel(status: 'OVERLOADED');
  }

  @override
  List<Object?> get props => [
        status,
        slotsAvailable,
        estimatedWaitSeconds,
        token,
      ];
}
