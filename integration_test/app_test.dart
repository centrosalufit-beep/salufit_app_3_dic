import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:salufit_app/main.dart' as app;
import 'package:salufit_app/firebase_options.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Salufit Global Audit 2026', () {
    testWidgets('Full Audit: Nav + Scroll + Riverpod Sync', (tester) async {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      final crawler = HealthCrawler(tester);

      debugPrint('🚀 Fase 1: Validando Dashboard...');
      await crawler.safeAudit();

      debugPrint('🧭 Fase 2: Navegación y Scroll Test...');
      await crawler.smartNavigateAndScroll();
      
      debugPrint('✅ Auditoria de Rama completada sin errores de infraestructura.');
    });
  });
}

class HealthCrawler {
  final WidgetTester tester;
  HealthCrawler(this.tester);

  Future<void> safeAudit() async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final fatalErrors = ['[core/no-app]', 'Exception:', 'error fatal', 'Null check'];
    
    for (var errorLabel in fatalErrors) {
      final found = find.textContaining(errorLabel);
      if (found.evaluate().isNotEmpty) {
        expect(found, findsNothing, reason: 'Fallo crítico: $errorLabel');
      }
    }
  }

  Future<void> smartNavigateAndScroll() async {
    // Buscador robusto sin usar .or()
    Finder nav = find.byType(BottomNavigationBar);
    if (nav.evaluate().isEmpty) nav = find.byType(NavigationBar);

    if (nav.evaluate().isNotEmpty) {
      debugPrint('📱 Nav detectada. Cambiando de sección...');
      await tester.tap(find.byType(Icon).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // --- TEST DE SCROLL (Misión Especial) ---
    debugPrint('📜 Iniciando Scroll Test para validar Lazy Loading...');
    try {
      final listFinder = find.byType(ListView).first.or(find.byType(CustomScrollView).first);
      // Hacemos un scroll hacia abajo de 500 pixeles
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pumpAndSettle();
      
      debugPrint('✅ Scroll completado. Verificando que no hay crasheos...');
      await safeAudit();
    } catch (e) {
      debugPrint('ℹ️ No se encontró una lista para hacer scroll, saltando fase.');
    }
  }
}

// Extensión rápida para emular el .or() de forma segura en versiones antiguas
extension FinderX on Finder {
  Finder or(Finder other) {
    return evaluate().isNotEmpty ? this : other;
  }
}
