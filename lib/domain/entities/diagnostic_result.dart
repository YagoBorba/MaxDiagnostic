import 'package:equatable/equatable.dart';

// Detalhes da conexão WiFi
class WifiDetails extends Equatable {
  final String ssid;
  final String bssid;
  final String band; // 2.4GHz, 5GHz, 6GHz
  final String standard; // 802.11n, 802.11ac, 802.11ax
  final String channelWidth; // 20MHz, 40MHz, 80MHz, 160MHz
  final int linkSpeedMbps;
  final int signalStrength; // dBm
  final int frequency; // MHz

  const WifiDetails({
    required this.ssid,
    required this.bssid,
    required this.band,
    required this.standard,
    required this.channelWidth,
    required this.linkSpeedMbps,
    required this.signalStrength,
    required this.frequency,
  });

  @override
  List<Object?> get props => [
    ssid, bssid, band, standard, channelWidth, 
    linkSpeedMbps, signalStrength, frequency
  ];
}

// Informações de localização
class LocationInfo extends Equatable {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String countryCode;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [latitude, longitude, city, country, countryCode];
}

// Resultado completo do diagnóstico
class DiagnosticResult extends Equatable {
  final String id;
  final DateTime timestamp;
  final double downloadSpeedMbps;
  final double uploadSpeedMbps;
  final double pingMs;
  final double jitterMs;
  final double packetLoss; // Percentual
  final String isp;
  final String ipAddress;
  final String serverLocation;
  final WifiDetails? wifiDetails; // Pode ser null se usar dados móveis
  final LocationInfo? locationInfo;
  final String connectionType; // WiFi, Mobile, Ethernet

  const DiagnosticResult({
    required this.id,
    required this.timestamp,
    required this.downloadSpeedMbps,
    required this.uploadSpeedMbps,
    required this.pingMs,
    required this.jitterMs,
    required this.packetLoss,
    required this.isp,
    required this.ipAddress,
    required this.serverLocation,
    required this.connectionType,
    this.wifiDetails,
    this.locationInfo,
  });

  @override
  List<Object?> get props => [
    id, timestamp, downloadSpeedMbps, uploadSpeedMbps,
    pingMs, jitterMs, packetLoss, isp, ipAddress,
    serverLocation, connectionType, wifiDetails, locationInfo,
  ];
}