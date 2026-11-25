import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart' as network_info_plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../network/network_info.dart';
import '../../data/datasources/speed_test_remote_datasource.dart';
import '../../data/datasources/server_capacity_remote_datasource.dart';
import '../../data/datasources/network_info_local_datasource.dart';
import '../../data/datasources/device_info_local_datasource.dart';
import '../../data/repositories/diagnostic_repository_impl.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/usecases/get_initial_network_info.dart';
import '../../domain/usecases/run_diagnostic_test.dart';
import '../../domain/usecases/check_server_reachability.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import '../../features/diagnostic/presentation/mock/mock_run_diagnostic_test_usecase.dart';
import '../../features/diagnostic/presentation/utils/progress_calculator.dart';
import '../config/app_config.dart';
import '../config/environment_config.dart';

final sl = GetIt.instance;

Future<void> init({bool useMockDiagnostic = false}) async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {}
  }
  
  sl.registerFactory(
      () => HomeCubit(
        getInitialNetworkInfo: sl(), 
        config: sl(),
        checkServerReachability: sl(),
      ));
  sl.registerFactory(() => DiagnosticCubit(
        runDiagnosticTestUseCase: sl(),
    diagnosticRepository: sl(),
        progressCalculator: sl<ProgressCalculator>(),
      ));

  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => EnvironmentConfig());
  sl.registerLazySingleton(() => GetInitialNetworkInfo(sl()));
  sl.registerLazySingleton(() => CheckServerReachability(sl()));
  
  if (useMockDiagnostic) {
    sl.registerLazySingleton<RunDiagnosticTest>(
      () => RunDiagnosticTest.mock(const MockRunDiagnosticTestUseCase()),
    );
  } else {
    sl.registerLazySingleton<RunDiagnosticTest>(() => RunDiagnosticTest(sl()));
  }

  sl.registerLazySingleton<ProgressCalculator>(() => ProgressCalculator.defaultConfig());

  sl.registerLazySingleton<DiagnosticRepository>(
    () => DiagnosticRepositoryImpl(
      speedTestRemoteDataSource: sl(),
      networkInfo: sl(),
      networkInfoLocalDataSource: sl(),
      deviceInfoLocalDataSource: sl(),
      serverCapacityRemoteDataSource: sl(),
      appConfig: sl(),
    ),
  );

  sl.registerLazySingleton<DeviceInfoLocalDataSource>(
    () => DeviceInfoLocalDataSourceImpl(
      deviceInfo: sl(),
    ),
  );

  sl.registerLazySingleton<NetworkInfoLocalDataSource>(
    () => NetworkInfoLocalDataSourceImpl(
      networkInfo: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton<SpeedTestRemoteDataSource>(
    () => SpeedTestRemoteDataSourceImpl(config: sl()),
  );

  sl.registerLazySingleton<ServerCapacityRemoteDataSource>(
    () => ServerCapacityRemoteDataSourceImpl(
      client: sl(),
      config: sl(),
    ),
  );

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<AppConfig>(() {
    String url = 'about:blank';
    try {
      if (dotenv.isInitialized) {
        url = dotenv.get('SPEED_TEST_URL', fallback: 'about:blank');
      }
    } catch (_) {
      url = 'about:blank';
    }
    debugPrint('[AppConfig] SPEED_TEST_URL resolved: $url');
    return AppConfig(speedTestUrl: url);
  });

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => DeviceInfoPlugin());
  sl.registerLazySingleton(() => network_info_plus.NetworkInfo());
  sl.registerLazySingleton(() => Connectivity());
}
