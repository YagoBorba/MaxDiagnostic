import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maxt_diagnostic/core/error/failures.dart';

abstract class AuthRepository {
  Stream<User?> get user;

  User? get currentUser;

  Future<Either<Failure, UserCredential>> signInWithGoogle();

  Future<void> signOut();
}
