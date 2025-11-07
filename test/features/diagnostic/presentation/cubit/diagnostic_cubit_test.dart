import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;

void main() {
  late DiagnosticCubit cubit;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
    await di.sl.reset();
    await di.init(useMockDiagnostic: true);
  });

  setUp(() {
    cubit = di.sl<DiagnosticCubit>();
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<DiagnosticCubit, DiagnosticState>(
    'uses MockRunDiagnosticTestUseCase: progresses and completes with results',
    build: () => cubit,
    act: (c) => c.startTest(),
    wait: const Duration(milliseconds: 800),
    verify: (c) {
      expect(c.state.globalStatus, GlobalTestStatus.complete);
      expect(c.state.finalResults, isNotNull);
      expect(c.state.tests['download']?.status, TestStatus.complete);
      expect(c.state.tests['upload']?.status, TestStatus.complete);
      expect(c.state.tests['latency']?.status, TestStatus.complete);
      expect(c.state.tests['additionalInfo']?.status, TestStatus.complete);
      expect(c.state.overallProgress, 100);
    },
  );
}
