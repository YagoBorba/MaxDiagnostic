import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart' as network_info_plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

import '../network/network_info.dart';
import '../../data/datasources/device_info_local_datasource.dart';
import '../../data/datasources/network_info_local_datasource.dart';
import '../../data/datasources/speed_test_remote_datasource.dart';
import '../../data/repositories/diagnostic_repository_impl.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/usecases/get_initial_network_info.dart';
import '../../domain/usecases/run_diagnostic_test.dart';
// TODO: Uncomment when cubits are created
// import '../../features/home/presentation/cubit/home_cubit.dart';
// import '../../features/diagnostic/presentation/cubit/diagnostic_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Home (TODO: Uncomment when implemented)
  // sl.registerFactory(
  //   () => HomeCubit(
  //     getInitialNetworkInfo: sl(),
  //   ),
  // );

  //! Features - Diagnostic (TODO: Uncomment when implemented)
  // sl.registerFactory(
  //   () => DiagnosticCubit(
  //     runDiagnosticTest: sl(),
  //   ),
  // );

  //! Use cases
  sl.registerLazySingleton(() => GetInitialNetworkInfo(sl()));
  sl.registerLazySingleton(() => RunDiagnosticTest(sl()));

  //! Repository
  sl.registerLazySingleton<DiagnosticRepository>(
    () => DiagnosticRepositoryImpl(
      deviceInfoLocalDataSource: sl(),
      networkInfoLocalDataSource: sl(),
      speedTestRemoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  //! Data sources
  sl.registerLazySingleton<DeviceInfoLocalDataSource>(
    () => DeviceInfoLocalDataSourceImpl(
      deviceInfo: sl(),
    ),
  );

  sl.registerLazySingleton<NetworkInfoLocalDataSource>(
    () => NetworkInfoLocalDataSourceImpl(
      networkInfo: sl(),
      connectivity: sl(),
      wifiInfo: sl(),
    ),
  );

  sl.registerLazySingleton<SpeedTestRemoteDataSource>(
    () => SpeedTestRemoteDataSourceImpl(),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => DeviceInfoPlugin());
  sl.registerLazySingleton(() => network_info_plus.NetworkInfo());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => WifiInfo());
}