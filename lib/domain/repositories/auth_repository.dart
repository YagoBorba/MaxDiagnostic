import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';

abstract class AuthRepository {
  Stream<User?> get user;

  User? get currentUser;

  Future<Either<Failure, UserCredential>> signInWithGoogle();

  Future<Either<Failure, UserCredential>> registerWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });
}
