// lib/app/navigation/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/view/diagnostic_screen.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/home_screen.dart';
// import 'package:maxt_diagnostic/features/results/presentation/view/results_screen.dart';

// GoRouter configuration
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      name: 'diagnostic',
      path: '/diagnostic',
      builder: (context, state) => const DiagnosticScreen(),
    ),
    // A rota de resultados será implementada depois
    // GoRoute(
    //   name: 'results',
    //   path: '/results',
    //   builder: (context, state) {
    //     final resultsJson = state.extra as String;
    //     return ResultsScreen(resultsJson: resultsJson);
    //   },
    // ),
  ],
);
