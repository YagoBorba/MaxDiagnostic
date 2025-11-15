import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:maxt_diagnostic/features/auth/presentation/view/login_screen.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/view/diagnostic_loading_screen.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/home_screen.dart';
import 'package:maxt_diagnostic/features/results/presentation/results_screen.dart';

class AppRouter {
  AppRouter({required AuthCubit authCubit}) : _authCubit = authCubit;

  final AuthCubit _authCubit;
  GoRouter? _router;

  AuthCubit get authCubit => _authCubit;

  GoRouter get config {
    _router ??= _buildRouter();
    return _router!;
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(_authCubit.stream),
      routes: [
        GoRoute(
          name: 'home',
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          name: 'diagnostic',
          path: '/diagnostic',
          builder: (context, state) => const DiagnosticLoadingScreen(),
        ),
        GoRoute(
          name: 'results',
          path: '/results',
          builder: (context, state) {
            final results = state.extra as FinalResultsEntity;
            return ResultsScreen(results: results);
          },
        ),
      ],
      redirect: (context, state) {
        final authStatus = _authCubit.state.status;
        final isAuthRoute = state.matchedLocation == '/login';

        if (authStatus == AuthStatus.unknown || authStatus == AuthStatus.loading) {
          return null;
        }

        if (authStatus == AuthStatus.unauthenticated && !isAuthRoute) {
          return '/login';
        }

        if (authStatus == AuthStatus.authenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
