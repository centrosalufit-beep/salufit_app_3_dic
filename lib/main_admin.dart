import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salufit_app/core/providers/locale_provider.dart';
import 'package:salufit_app/features/auth/presentation/auth_wrapper.dart';
import 'package:salufit_app/firebase_options.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('es_ES');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ProviderScope(child: SalufitAdminApp()));
  } catch (e) {
    debugPrint('Error Salufit Start: $e');
  }
}

class SalufitAdminApp extends ConsumerStatefulWidget {
  const SalufitAdminApp({super.key});

  @override
  ConsumerState<SalufitAdminApp> createState() => _SalufitAdminAppState();
}

class _SalufitAdminAppState extends ConsumerState<SalufitAdminApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp(
      title: 'Salufit Admin 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF009688),
      ),
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}
