import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxt_diagnostic/app/navigation/app_router.dart';
import 'package:maxt_diagnostic/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:maxt_diagnostic/features/home/presentation/cubit/home_cubit.dart';
import 'package:maxt_diagnostic/firebase_options.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('🔧 Starting MaxDiagnostic in debug mode - WebView debugging enabled');

  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = di.sl<AppRouter>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => appRouter.authCubit..checkAuthStatus(),
        ),
        BlocProvider<HomeCubit>(
          create: (_) => di.sl<HomeCubit>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'MaxT Diagnostic',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter.config,
      ),
    );
  }
}
