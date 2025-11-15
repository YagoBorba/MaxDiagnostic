import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';
import 'package:maxt_diagnostic/domain/repositories/auth_repository.dart';

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
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return const Left(
          ServerFailure(message: 'Não foi possível obter o ID token do Google.'),
        );
      }

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
          debugPrint('Falha ao obter accessToken do Google: $error');
        }
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return Right(userCredential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const Left(ServerFailure(message: 'Login com Google cancelado.'));
      }
      if (kDebugMode) {
        debugPrint('Erro de autenticação Google: $error');
      }
      final String details = error.description ?? error.code.name;
      return Left(ServerFailure(message: 'Erro ao fazer login com Google: $details'));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Erro no signInWithGoogle: $error');
      }
      return Left(ServerFailure(message: 'Erro ao fazer login com Google: $error'));
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
