part of 'auth_cubit.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.successMessage,
  });

  const AuthState.unknown() : this._();

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({String? error, String? successMessage})
      : this._(
          status: AuthStatus.unauthenticated,
          error: error,
          successMessage: successMessage,
        );

  final AuthStatus status;
  final User? user;
  final String? error;
  final String? successMessage;

  @override
  List<Object?> get props => [status, user, error, successMessage];
}
