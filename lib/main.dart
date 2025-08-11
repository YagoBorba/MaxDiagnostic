import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxt_diagnostic/features/speed_test/cubit/speed_test_cubit.dart';
import 'package:maxt_diagnostic/features/speed_test/screens/speed_test_screen.dart';
import 'core/di/injection_container.dart' as di;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<SpeedTestCubit>(),
      child: MaterialApp(
        title: 'MaxT Diagnostic',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SpeedTestScreen(),
      ),
    );
  }
}