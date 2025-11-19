import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../../core/config/environment_config.dart';
import '../../../core/error/exceptions.dart';
import '../models/server_capacity_model.dart';

abstract class ServerCapacityRemoteDataSource {
  Future<ServerCapacityModel> checkCapacity();

  /// Reserves a test slot. Throws [ServerException] if no slot is available.
  Future<ServerCapacityModel> reserveSlot(String clientId);

  Future<void> releaseSlot(String token);
}

class ServerCapacityRemoteDataSourceImpl implements ServerCapacityRemoteDataSource {
  ServerCapacityRemoteDataSourceImpl({
    required this.client,
    required this.config,
  });

  final http.Client client;
  final EnvironmentConfig config;

  static const _headers = {'Content-Type': 'application/json'};

  String get _baseUrl {
    final uri = Uri.parse(config.speedTestServerUrl);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    final rootUrl = '${uri.scheme}://${uri.host}$portPart';
    return '$rootUrl/api.php';
  }

  @override
  Future<ServerCapacityModel> checkCapacity() async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'action': 'check_capacity',
    });

    try {
      final response = await client.get(uri, headers: _headers);

      if (response.statusCode == 200 || response.statusCode == 429) {
        return ServerCapacityModel.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 503) {
        throw const ServerException(
          'Service Temporarily Unavailable (OVERLOADED)',
          statusCode: 503,
        );
      }

      throw ServerException(
        'Failed to check server capacity',
        statusCode: response.statusCode,
      );
    } on FormatException {
      throw const ServerException('Malformed response when checking capacity');
    } on Exception {
      throw const ServerException('Network or I/O error during capacity check.');
    }
  }

  @override
  Future<ServerCapacityModel> reserveSlot(String clientId) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'clientId': clientId,
      'action': 'reserve_slot',
    });

    try {
      final response = await client.post(uri, headers: _headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        if (jsonResponse['status'] == 'GRANTED') {
          return ServerCapacityModel.fromJson(jsonResponse);
        }

        throw const ServerException('Reservation failed: Server logic error.');
      }

      if (response.statusCode == 429) {
        return ServerCapacityModel.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 503) {
        throw const ServerException(
          'Service Temporarily Unavailable (OVERLOADED)',
          statusCode: 503,
        );
      }

      throw ServerException(
        'Failed to reserve slot: Status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on FormatException {
      throw const ServerException('Malformed response during slot reservation.');
    } on Exception {
      throw const ServerException('Network or I/O error during slot reservation.');
    }
  }

  @override
  Future<void> releaseSlot(String token) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'token': token,
      'action': 'release_slot',
    });

    try {
      final response = await client.get(uri, headers: _headers);
      if (response.statusCode >= 400) {
        developer.log(
          'Failed to confirm slot release. Status code: ${response.statusCode}',
          name: 'ServerCapacityRemoteDataSource',
        );
      }
    } on Exception catch (error, stackTrace) {
      developer.log(
        'Failed to confirm slot release to server: $token',
        name: 'ServerCapacityRemoteDataSource',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
