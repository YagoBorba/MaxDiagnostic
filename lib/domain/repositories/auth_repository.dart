import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';

/// Interface principal para operações de autenticação.
/// Abstrai a implementação concreta (Firebase, Mock, etc) do domínio.
abstract class AuthRepository {
  /// Stream que emite o estado atual do usuário.
  /// Emite [null] quando não há usuário logado.
  Stream<User?> get user;

  /// Retorna o usuário autenticado no momento, se houver.
  /// Útil para verificações síncronas de estado.
  User? get currentUser;

  /// Inicia o fluxo de autenticação com o Google.
  /// Deve lidar com o popup nativo e troca de credenciais.
  Future<Either<Failure, UserCredential>> signInWithGoogle();

  /// Cria uma nova conta usando e-mail e senha.
  Future<Either<Failure, UserCredential>> registerWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Autentica um usuário existente usando e-mail e senha.
  Future<Either<Failure, UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Encerra a sessão do usuário (Logout).
  Future<void> signOut();

  /// Envia um e-mail de recuperação de senha para o endereço fornecido.
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });
}