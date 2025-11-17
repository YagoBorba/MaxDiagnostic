import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/domain/repositories/auth_repository.dart';

/// Implementação concreta do repositório usando Firebase Auth e Google Sign In.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<Either<Failure, UserCredential>> signInWithGoogle() async {
    try {
      // Dispara o fluxo nativo de autenticação (popup ou redirecionamento)
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      // Obtém os detalhes de autenticação da requisição
      final GoogleSignInAuthentication googleAuth = account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return const Left(
          ServerFailure(message: 'Não foi possível obter o ID token do Google.'),
        );
      }

      // Tenta obter o accessToken. Necessário em algumas configurações de escopo,
      // mas nem sempre obrigatório dependendo do provedor.
      String? accessToken;
      try {
        const scopes = <String>['email', 'profile'];
        final GoogleSignInClientAuthorization? existingAuthorization =
            await account.authorizationClient.authorizationForScopes(scopes);
        final GoogleSignInClientAuthorization tokens =
            existingAuthorization ??
                await account.authorizationClient.authorizeScopes(scopes);
        accessToken = tokens.accessToken;
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Falha ao obter accessToken do Google (aviso não crítico): $error');
        }
      }

      // Cria a credencial do Firebase com os tokens obtidos do Google
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      // Finalmente, autentica no Firebase
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return Right(userCredential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const Left(ServerFailure(message: 'Login com Google cancelado pelo usuário.'));
      }
      if (kDebugMode) {
        debugPrint('Erro de autenticação Google: $error');
      }
      final String details = error.description ?? error.code.name;
      return Left(ServerFailure(message: 'Erro ao fazer login com Google: $details'));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Erro genérico no signInWithGoogle: $error');
      }
      return Left(ServerFailure(message: 'Erro ao fazer login com Google: $error'));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(userCredential);
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint('Erro no registerWithEmail: $error');
      }
      return Left(ServerFailure(message: _mapFirebaseError(error.code)));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(userCredential);
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint('Erro no signInWithEmail: $error');
      }
      return Left(ServerFailure(message: _mapFirebaseError(error.code)));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<void> signOut() async {
    // É importante deslogar de ambos para evitar problemas de cache de sessão
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint('Erro no sendPasswordResetEmail: $error');
      }
      return Left(ServerFailure(message: _mapFirebaseError(error.code)));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  /// Traduz os códigos de erro do Firebase para mensagens amigáveis ao usuário.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'weak-password':
        return 'A senha fornecida é muito fraca.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'user-not-found':
        return 'Nenhum usuário encontrado para este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'user-disabled':
        return 'Este usuário foi desabilitado.';
      case 'invalid-credential':
        return 'As credenciais fornecidas são inválidas.';
      default:
        return 'Ocorreu um erro desconhecido. Tente novamente.';
    }
  }
}