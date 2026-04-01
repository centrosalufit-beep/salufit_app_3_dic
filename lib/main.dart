import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salufit_app/features/auth/presentation/auth_wrapper.dart';
import 'package:salufit_app/features/auth/presentation/version_gate.dart';
import 'package:salufit_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // CORRECCIÓN: Se elimina el 'null' redundante para el linter
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
    debugPrint('❌ Error Crítico en main: $e');
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
    return MaterialApp(
      title: 'Salufit 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
        useMaterial3: true,
      ),
      home: const VersionGate(child: AuthWrapper()),
    );
  }
}
