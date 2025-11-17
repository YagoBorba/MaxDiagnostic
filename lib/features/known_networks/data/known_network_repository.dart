import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maxt_diagnostic/features/known_networks/domain/entities/known_network.dart';

/// Repositório responsável por persistir as redes Wi-Fi salvas pelo usuário.
/// Utiliza sub-coleções no Firestore para garantir isolamento de dados por usuário.
class KnownNetworkRepository {
  KnownNetworkRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Retorna a referência para a coleção do usuário autenticado.
  /// Retorna [null] se não houver usuário logado, prevenindo acessos indevidos.
  /// Estrutura: users/{uid}/known_networks
  CollectionReference<Map<String, dynamic>>? get _userCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    return _firestore.collection('users').doc(uid).collection('known_networks');
  }

  /// Escuta mudanças nas redes salvas do usuário em tempo real.
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

  /// Salva ou atualiza uma rede.
  /// Se [remoteId] for nulo, cria um novo documento.
  Future<void> saveNetwork(KnownNetwork network) async {
    final collection = _userCollection;
    if (collection == null) {
      throw StateError('Usuário não autenticado. Impossível salvar rede.');
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