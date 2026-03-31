import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salufit_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app launch', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: app.SalufitApp(),
        ),
      );
      expect(find.byType(app.SalufitApp), findsOneWidget);
    });
  });
}
