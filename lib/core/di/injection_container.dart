import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart' as network_info_plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../network/network_info.dart';
import '../../data/datasources/speed_test_remote_datasource.dart';
import '../../data/datasources/ping_remote_datasource.dart';
import '../../data/datasources/network_info_local_datasource.dart';
import '../../data/datasources/device_info_local_datasource.dart';
import '../../data/repositories/diagnostic_repository_impl.dart';
import '../../domain/repositories/diagnostic_repository.dart';
import '../../domain/usecases/get_initial_network_info.dart';
import '../../domain/usecases/run_diagnostic_test.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import '../../features/diagnostic/presentation/mock/mock_run_diagnostic_test_usecase.dart';
import '../../features/diagnostic/presentation/utils/progress_calculator.dart';
import '../config/app_config.dart';

final sl = GetIt.instance;

Future<void> init({bool useMockDiagnostic = false}) async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  
  sl.registerFactory(
      () => HomeCubit(getInitialNetworkInfo: sl(), config: sl()));
  sl.registerFactory(() => DiagnosticCubit(
        runDiagnosticTestUseCase: sl(),
        progressCalculator: sl<ProgressCalculator>(),
      ));

  sl.registerLazySingleton(() => GetInitialNetworkInfo(sl()));
  
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
      pingRemoteDataSource: sl(),
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

  sl.registerLazySingleton<PingRemoteDataSource>(
    () => PingRemoteDataSourceImpl(
      host: sl<AppConfig>().pingHost,
      count: sl<AppConfig>().pingCount,
      intervalSeconds: sl<AppConfig>().pingIntervalSeconds,
      timeoutSeconds: sl<AppConfig>().pingTimeoutSeconds,
    ),
  );

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<AppConfig>(() {
    String runnerUrl = 'about:blank';
    String downloadUrl = 'http://speedtest.tele2.net/10MB.zip';
    String uploadUrl = 'http://speedtest.tele2.net/upload.php';
    int fileSizeBytes = 200000;

    try {
      if (dotenv.isInitialized) {
        runnerUrl = dotenv.get('SPEED_TEST_URL', fallback: runnerUrl);
        downloadUrl = dotenv.get('SPEED_TEST_DOWNLOAD_URL', fallback: downloadUrl);
        uploadUrl = dotenv.get('SPEED_TEST_UPLOAD_URL', fallback: uploadUrl);
        fileSizeBytes = int.tryParse(
              dotenv.get('SPEED_TEST_FILE_SIZE_BYTES', fallback: '$fileSizeBytes'),
            ) ??
            fileSizeBytes;
      }
    } catch (_) {
      // ignore and keep defaults
    }

    debugPrint('[AppConfig] SPEED_TEST_URL resolved: $runnerUrl');
    debugPrint('[AppConfig] SPEED_TEST_DOWNLOAD_URL resolved: $downloadUrl');
    debugPrint('[AppConfig] SPEED_TEST_UPLOAD_URL resolved: $uploadUrl');
    debugPrint('[AppConfig] SPEED_TEST_FILE_SIZE_BYTES: $fileSizeBytes');

    return AppConfig(
      speedTestUrl: runnerUrl.isEmpty ? 'native-plugin' : runnerUrl,
      speedTestDownloadUrl: downloadUrl,
      speedTestUploadUrl: uploadUrl,
      speedTestFileSizeBytes: fileSizeBytes,
    );
  });

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => DeviceInfoPlugin());
  sl.registerLazySingleton(() => network_info_plus.NetworkInfo());
  sl.registerLazySingleton(() => Connectivity());
}
