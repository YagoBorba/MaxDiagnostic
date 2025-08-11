import 'package:get_it/get_it.dart';
import '../../features/speed_test/cubit/speed_test_cubit.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // Cubit
  sl.registerFactory(() => SpeedTestCubit());
}