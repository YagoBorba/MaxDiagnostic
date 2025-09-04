import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maxt_diagnostic/app/navigation/app_router.dart';
import 'package:maxt_diagnostic/features/home/presentation/cubit/home_cubit.dart';
import 'core/di/injection_container.dart' as di;
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // WebView debugging é automaticamente habilitado em debug builds
  debugPrint('🔧 Starting MaxDiagnostic in debug mode - WebView debugging enabled');
  
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = di.sl<AppConfig>();
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        BlocProvider(create: (_) => di.sl<HomeCubit>()),
      ],
      child: MaterialApp.router(
        title: 'MaxT Diagnostic',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router, // Usando a configuração do GoRouter
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Max Diagnostic'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.network_check,
              size: 80,
              color: Colors.indigo,
            ),
            SizedBox(height: 20),
            Text(
              'MaxT Diagnostic',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Architecture foundation ready!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
