import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maxt_diagnostic/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    _userSubscription = _authRepository.user.listen(_onAuthUserChanged);
  }

  final AuthRepository _authRepository;
  StreamSubscription<User?>? _userSubscription;

  void _onAuthUserChanged(User? user) {
    if (user == null) {
      emit(const AuthState.unauthenticated());
    } else {
      emit(AuthState.authenticated(user));
    }
  }

  void checkAuthStatus() {
    _onAuthUserChanged(_authRepository.currentUser);
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());
    final result = await _authRepository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthState.unauthenticated(error: failure.message)),
      (_) => null,
    );
  }

  Future<void> registerWithEmail(String email, String password) async {
    emit(const AuthState.loading());
    final result = await _authRepository.registerWithEmailAndPassword(
      email: email,
      password: password,
    );
    result.fold(
      (failure) => emit(AuthState.unauthenticated(error: failure.message)),
      (_) => null,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthState.loading());
    final result = await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    result.fold(
      (failure) => emit(AuthState.unauthenticated(error: failure.message)),
      (_) => null,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final result = await _authRepository.sendPasswordResetEmail(email: email);
    result.fold(
      (failure) => emit(AuthState.unauthenticated(error: failure.message)),
      (_) => emit(
        const AuthState.unauthenticated(
          successMessage:
              'E-mail de redefinição enviado. Verifique sua caixa de entrada.',
        ),
      ),
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
