import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salufit_app/main.dart';

void main() {
  testWidgets('Prueba de humo de arquitectura - ProviderScope y AuthWrapper',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    expect(find.byType(AuthWrapper), findsOneWidget);
  });
}
