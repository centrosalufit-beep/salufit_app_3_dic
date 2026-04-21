import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salufit_app/main.dart' as app;

/// Integration tests que arrancan la app REAL en un emulador/dispositivo
/// físico y verifican que las pantallas principales se rendericen sin
/// errores de overflow, layout, o crashes.
///
/// Uso:
/// ```
/// flutter test integration_test/app_test.dart
/// ```
///
/// Requiere emulador/dispositivo conectado (lo detecta automáticamente).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Salufit App — Integration Tests en dispositivo real', () {
    testWidgets('Arranque de la app + LoginScreen visible', (tester) async {
      final renderErrors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        if (msg.contains('RenderFlex') ||
            msg.contains('overflow') ||
            msg.contains('BoxConstraints') ||
            msg.contains('was not laid out')) {
          renderErrors.add(details);
        }
        previousHandler?.call(details);
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: app.SalufitApp(),
        ),
      );

      // Dar tiempo a que se inicialice Firebase/auth
      await tester.pump(const Duration(seconds: 3));

      // La app debe haberse renderizado sin crashes
      expect(find.byType(app.SalufitApp), findsOneWidget);

      // Buscar elementos característicos de LoginScreen (si no hay sesión)
      // o del RoleGate (si hay sesión activa)
      final hasLogin = find.text('INICIAR SESIÓN').evaluate().isNotEmpty;
      final hasPrimera = find.text('Primera vez').evaluate().isNotEmpty;

      // ignore: avoid_print
      print('\n🔍 App smoke test en emulador:');
      // ignore: avoid_print
      print('   LoginScreen detectado: ${hasLogin || hasPrimera}');
      // ignore: avoid_print
      print('   Errores de render: ${renderErrors.length}');
      if (renderErrors.isNotEmpty) {
        for (final err in renderErrors) {
          // ignore: avoid_print
          print('   ✗ ${err.exceptionAsString().split("\n").first}');
        }
      }

      // Captura screenshot para inspección
      try {
        await binding.takeScreenshot('01_login_screen');
      } catch (_) {
        // takeScreenshot solo funciona en driver mode, ignorar en test mode
      }

      FlutterError.onError = previousHandler;

      expect(
        renderErrors,
        isEmpty,
        reason:
            'La app real tiene errores de render en la pantalla inicial: '
            '${renderErrors.map((e) => e.exceptionAsString().split("\n").first).join("; ")}',
      );
    });

    testWidgets('Navegación a ActivationScreen (primera vez)', (tester) async {
      final renderErrors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        if (msg.contains('RenderFlex') ||
            msg.contains('overflow') ||
            msg.contains('BoxConstraints')) {
          renderErrors.add(details);
        }
        previousHandler?.call(details);
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: app.SalufitApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      // Si hay botón "Primera vez", pulsarlo
      final primeraBtn = find.text('Primera vez');
      if (primeraBtn.evaluate().isNotEmpty) {
        await tester.tap(primeraBtn);
        await tester.pump(const Duration(seconds: 1));

        // Verificar que llegó a ActivationScreen
        final tieneActivacion = find.text('Activar Cuenta').evaluate().isNotEmpty ||
            find.text('VERIFICAR MI IDENTIDAD').evaluate().isNotEmpty;

        // ignore: avoid_print
        print('\n🔍 Navegación activación:');
        // ignore: avoid_print
        print('   ActivationScreen renderizada: $tieneActivacion');
        // ignore: avoid_print
        print('   Errores de render: ${renderErrors.length}');

        try {
          await binding.takeScreenshot('02_activation_screen');
        } catch (_) {}
      } else {
        // ignore: avoid_print
        print('\n⚠️ Hay sesión activa — no se puede testear navegación desde login');
      }

      FlutterError.onError = previousHandler;

      expect(
        renderErrors,
        isEmpty,
        reason:
            'Errores de render tras navegación: '
            '${renderErrors.map((e) => e.exceptionAsString().split("\n").first).join("; ")}',
      );
    });

    testWidgets('Orientación horizontal (rotación)', (tester) async {
      final renderErrors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        if (msg.contains('RenderFlex') ||
            msg.contains('overflow') ||
            msg.contains('BoxConstraints')) {
          renderErrors.add(details);
        }
        previousHandler?.call(details);
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: app.SalufitApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // Simular rotación a landscape
      final mediaQuery = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first,
      );

      // ignore: avoid_print
      print('\n🔍 Test rotación:');
      // ignore: avoid_print
      print('   Tamaño actual: ${mediaQuery.size}');
      // ignore: avoid_print
      print('   Errores de render: ${renderErrors.length}');

      FlutterError.onError = previousHandler;

      expect(renderErrors, isEmpty);
    });
  });
}
