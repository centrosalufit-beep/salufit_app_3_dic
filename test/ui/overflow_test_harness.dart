import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';

/// Tamaños representativos de dispositivos reales.
class DeviceSize {
  const DeviceSize(this.name, this.width, this.height);
  final String name;
  final double width;
  final double height;

  Size get size => Size(width, height);

  static const iPhoneSE = DeviceSize('iPhone SE', 320, 568);
  static const iPhone15 = DeviceSize('iPhone 15 Pro', 393, 852);
  static const androidSmall = DeviceSize('Android Small (Galaxy A03)', 360, 640);
  static const androidStandard = DeviceSize('Android Standard (Pixel 7)', 412, 915);
  static const ipad = DeviceSize('iPad Mini', 768, 1024);
  static const desktop = DeviceSize('Desktop Windows (.exe)', 1440, 900);

  static const allForMobileScreens = [iPhoneSE, iPhone15, androidSmall, androidStandard, ipad];
  static const allForDesktopScreens = [desktop];
}

/// Ejecuta un widget en todos los tamaños y reporta overflow usando
/// `tester.takeException()` que consume la excepción y la devuelve.
Future<Map<String, String>> runAcrossDevices({
  required WidgetTester tester,
  required Widget Function() buildWidget,
  required List<DeviceSize> devices,
  Duration settleTimeout = const Duration(milliseconds: 500),
}) async {
  final results = <String, String>{};

  for (final device in devices) {
    await tester.binding.setSurfaceSize(device.size);
    tester.view.physicalSize = device.size;
    tester.view.devicePixelRatio = 1.0;

    // Pump inicial
    await tester.pumpWidget(buildWidget());
    final errorAfterPump = tester.takeException();

    // Try to settle
    try {
      await tester.pumpAndSettle(settleTimeout);
    } catch (_) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final errorAfterSettle = tester.takeException();

    // Recopilar errores
    final errors = <String>[];
    for (final err in [errorAfterPump, errorAfterSettle]) {
      if (err == null) continue;
      final msg = err.toString();
      if (_isRenderError(msg)) {
        errors.add(msg.split('\n').first);
      }
    }

    results[device.name] = errors.isEmpty ? 'OK' : 'FALLOS (${errors.length}): ${errors.join(" | ")}';
  }

  // Una pasada final por si queda algo pendiente
  tester.takeException();
  return results;
}

bool _isRenderError(String msg) {
  return msg.contains('RenderFlex') ||
      msg.contains('overflow') ||
      msg.contains('A RenderBox was not laid out') ||
      msg.contains('Constraints forces an infinite') ||
      msg.contains('BoxConstraints has') ||
      msg.contains('cannot be positive infinity');
}

/// Crea un MaterialApp con ProviderScope + overrides de Firebase mockeado.
Widget wrapInAppWithMocks(
  Widget child, {
  FakeFirebaseFirestore? firestore,
  MockFirebaseAuth? auth,
}) {
  final db = firestore ?? FakeFirebaseFirestore();
  final authInstance = auth ??
      MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        ),
      );

  return ProviderScope(
    overrides: [
      firebaseFirestoreProvider.overrideWithValue(db),
      firebaseAuthProvider.overrideWithValue(authInstance),
    ],
    child: MaterialApp(
      home: child,
      debugShowCheckedModeBanner: false,
    ),
  );
}

/// Imprime un reporte legible por pantalla.
void printReport(String screenName, Map<String, String> results) {
  final ok = results.values.where((v) => v == 'OK').length;
  final total = results.length;
  final marker = ok == total ? '✅' : '⚠️';

  // ignore: avoid_print
  print('\n$marker $screenName — $ok/$total dispositivos OK');
  results.forEach((device, result) {
    final icon = result == 'OK' ? '  ✓' : '  ✗';
    // ignore: avoid_print
    print('$icon  $device: $result');
  });
}

/// Cuenta fallos reales.
int countRealFailures(Map<String, String> results) {
  return results.values.where((v) => v != 'OK').length;
}

/// Asserción que falla limpiamente si hay overflow.
void assertNoOverflow(Map<String, String> results, String screenName) {
  final fails = countRealFailures(results);
  if (fails > 0) {
    final detail = results.entries
        .where((e) => e.value != 'OK')
        .map((e) => '${e.key}: ${e.value}')
        .join(' | ');
    fail('$screenName: $fails fallo(s) — $detail');
  }
}
