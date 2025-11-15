import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maxt_diagnostic/features/known_networks/domain/entities/known_network.dart';

class KnownNetworkRepository {
  KnownNetworkRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _userCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    return _firestore.collection('users').doc(uid).collection('known_networks');
  }

  Stream<List<KnownNetwork>> watchNetworks() {
    final collection = _userCollection;
    if (collection == null) {
      return Stream.value(const []);
    }

    return collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(KnownNetwork.fromFirestore)
            .toList(growable: false));
  }

  Future<void> saveNetwork(KnownNetwork network) async {
    final collection = _userCollection;
    if (collection == null) {
      throw StateError('Usuário não autenticado.');
    }

    final payload = network.toFirestore();
    if (network.remoteId == null) {
      await collection.add(payload);
      return;
    }
    await collection.doc(network.remoteId).update(payload);
  }

  Future<void> deleteNetwork(String remoteId) async {
    final collection = _userCollection;
    if (collection == null) {
      throw StateError('Usuário não autenticado.');
    }
    await collection.doc(remoteId).delete();
  }
}
