import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/init_helper.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/presentation/login_screen.dart';
import 'package:salufit_app/features/auth/presentation/terms_acceptance_screen.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/home/presentation/home_screen.dart';
import 'package:salufit_app/layouts/desktop_scaffold.dart';
import 'package:salufit_app/layouts/responsive_layout.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

void main() async {
  await InitHelper.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Salufit App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF009688)),
        ),
      ),
      error: (Object err, StackTrace? stack) => Scaffold(
        body: Center(child: Text('Error de autenticaciÃƒÆ’Ã‚Â³n: $err')),
      ),
      data: (User? user) {
        if (user == null) {
          return const LoginScreen();
        }

        final userProfileAsync = ref.watch(userProfileProvider);

        return userProfileAsync.when(
          loading: () => const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            ),
          ),
          error: (Object err, StackTrace? stack) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    const Text('Error cargando perfil.'),
                    ElevatedButton(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      child: const Text('Cerrar SesiÃƒÆ’Ã‚Â³n'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (DocumentSnapshot<Map<String, dynamic>> snapshot) {
            final data = snapshot.data();
            if (data == null) return const LoginScreen();

            final role = data.safeString('rol', defaultValue: 'cliente');
            final userId = user.uid;
            debugPrint('ÃƒÂ°Ã…Â¸Ã¢â‚¬Â Ã¢â‚¬Â MI UID ACTUAL ES: ${user.uid}');

            if (!data.safeBool('termsAccepted')) {
              return TermsAcceptanceScreen(userId: userId, userRole: role);
            }

            if (AppConfig.esStaff(role)) {
              debugPrint(
                'ÃƒÂ°Ã…Â¸Ã‚ÂÃ¢â‚¬â€ÃƒÂ¯Ã‚Â¸Ã‚Â CONSTRUYENDO UI - Rol enviado a Home: $role',
              );
              return ResponsiveLayout(
                mobileScaffold: SalufitScaffold(
                  body: HomeScreen(userId: userId, userRole: role),
                ),
                desktopScaffold:
                    DesktopScaffold(userId: userId, userRole: role),
              );
            }

            // Si es cliente, cargamos su pantalla especÃƒÆ’Ã‚Â­fica
            return HomeScreen(userId: userId, userRole: role);
          },
        );
      },
    );
  }
}
