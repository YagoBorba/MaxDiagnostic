import 'package:go_router/go_router.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/view/diagnostic_loading_screen.dart';
import 'package:maxt_diagnostic/features/home/presentation/view/home_screen.dart';
import 'package:maxt_diagnostic/domain/entities/final_results_entity.dart';
import 'package:maxt_diagnostic/features/results/presentation/results_screen.dart';

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
);
