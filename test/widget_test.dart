import 'package:flutter_test/flutter_test.dart';
import 'package:maxt_diagnostic/main.dart';
import 'package:maxt_diagnostic/core/di/injection_container.dart' as di;

void main() {
  testWidgets('App should start without crashing', (WidgetTester tester) async {
    // Inicializar as dependências antes de construir o app
    await di.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loaded correctly
    expect(find.text('MaxDiagnostic'), findsOneWidget);
  });
}
