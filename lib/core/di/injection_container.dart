import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart' as network_info_plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../network/network_info.dart';
import '../../data/datasources/speed_test_remote_datasource.dart';
import '../../data/datasources/network_info_local_datasource.dart';
import '../../data/repositories/diagnostic_repository_impl.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/usecases/get_initial_network_info.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import '../config/app_config.dart';

final sl = GetIt.instance;

String _getSpeedTestUrl() {
  try {
    final envFile = File('.env');
    if (envFile.existsSync()) {
      final content = envFile.readAsStringSync();
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.trim().startsWith('SPEED_TEST_URL=')) {
          return line.split('=')[1].trim();
        }
      }
    }
  } catch (e) {
    // .
  }
  
  return 'http://localhost:7000/librespeed_runner.html';
}

Future<void> init() async {
  sl.registerFactory(
      () => HomeCubit(getInitialNetworkInfo: sl(), config: sl()));
  sl.registerFactory(() => DiagnosticCubit());

  sl.registerLazySingleton(() => GetInitialNetworkInfo(sl()));

  sl.registerLazySingleton<DiagnosticRepository>(
    () => DiagnosticRepositoryImpl(
      speedTestRemoteDataSource: sl(),
      networkInfo: sl(),
      networkInfoLocalDataSource: sl(),
    ),
  );

  //! Data sources (TODO: Re-enable when all import issues are resolved)
  // sl.registerLazySingleton<DeviceInfoLocalDataSource>(
  //   () => DeviceInfoLocalDataSourceImpl(
  //     deviceInfo: sl(),
  //   ),
  // );

  sl.registerLazySingleton<NetworkInfoLocalDataSource>(
    () => NetworkInfoLocalDataSourceImpl(
      networkInfo: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton<SpeedTestRemoteDataSource>(
    () => SpeedTestRemoteDataSourceImpl(
      speedTestUrl: _getSpeedTestUrl(),
    ),
  );

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<AppConfig>(() => AppConfig());

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => DeviceInfoPlugin());
  sl.registerLazySingleton(() => network_info_plus.NetworkInfo());
  sl.registerLazySingleton(() => Connectivity());
}
