import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart' as network_info_plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../network/network_info.dart';
import '../../data/datasources/speed_test_remote_datasource.dart';
import '../../data/datasources/network_info_local_datasource.dart';
import '../../data/datasources/device_info_local_datasource.dart';
import '../../data/repositories/diagnostic_repository_impl.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/usecases/get_initial_network_info.dart';
import '../../domain/usecases/run_diagnostic_test.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import '../config/app_config.dart';

final sl = GetIt.instance;

Future<void> init() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  sl.registerFactory(
      () => HomeCubit(getInitialNetworkInfo: sl(), config: sl()));
  sl.registerFactory(() => DiagnosticCubit(runDiagnosticTestUseCase: sl()));

  sl.registerLazySingleton(() => GetInitialNetworkInfo(sl()));
  sl.registerLazySingleton(() => RunDiagnosticTest(sl()));

  sl.registerLazySingleton<DiagnosticRepository>(
    () => DiagnosticRepositoryImpl(
      speedTestRemoteDataSource: sl(),
      networkInfo: sl(),
      networkInfoLocalDataSource: sl(),
      deviceInfoLocalDataSource: sl(),
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

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<AppConfig>(() {
    String url = 'about:blank';
    try {
      if (dotenv.isInitialized) {
        // Use get with fallback to avoid exceptions on missing key
        url = dotenv.get('SPEED_TEST_URL', fallback: 'about:blank');
      }
    } catch (_) {
      // Keep safe default when dotenv isn't available or key missing
      url = 'about:blank';
    }
    return AppConfig(speedTestUrl: url);
  });

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => DeviceInfoPlugin());
  sl.registerLazySingleton(() => network_info_plus.NetworkInfo());
  sl.registerLazySingleton(() => Connectivity());
}
