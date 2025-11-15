import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class KnownNetwork extends Equatable {
  final String? remoteId;
  final String ownerUid;
  final String name;
  final String bssid;
  final String ssid;
  final DateTime updatedAt;

  const KnownNetwork({
    this.remoteId,
    required this.ownerUid,
    required this.name,
    required this.bssid,
    required this.ssid,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [remoteId, ownerUid, name, bssid, ssid, updatedAt];

  Map<String, dynamic> toFirestore() => {
        'ownerUid': ownerUid,
        'name': name,
        'bssid': bssid,
        'ssid': ssid,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory KnownNetwork.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Documento de rede conhecido sem dados.');
    }
    return KnownNetwork(
      remoteId: doc.id,
      ownerUid: data['ownerUid'] as String,
      name: data['name'] as String,
      bssid: data['bssid'] as String,
      ssid: data['ssid'] as String,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
