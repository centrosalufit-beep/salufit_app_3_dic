import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salufit_app/features/auth/presentation/auth_wrapper.dart';
import 'package:salufit_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferir portrait pero permitir que Android gestione la orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Capturar errores de Flutter (widgets, rendering)
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  // Capturar errores asíncronos no manejados
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error');
    return true; // No propagar — evita crash
  };

  try {
    await initializeDateFormatting('es');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } else {
      await FirebaseAppCheck.instance.activate();
    }
  } catch (e) {
    debugPrint('Error Crítico en main: $e');
  }

  runApp(
    const ProviderScope(
      child: SalufitApp(),
    ),
  );
}

class SalufitApp extends StatelessWidget {
  const SalufitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge: barras transparentes para Android 15+
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      title: 'Salufit 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
        useMaterial3: true,
      ),
      // ErrorWidget para evitar pantalla roja en producción
      builder: (context, child) {
        ErrorWidget.builder = (details) => Material(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Ha ocurrido un error.\nPor favor, reinicia la aplicación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ),
              ),
            );
        return child ?? const SizedBox.shrink();
      },
      home: const AuthWrapper(),
    );
  }
}
