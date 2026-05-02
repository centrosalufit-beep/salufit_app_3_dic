import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/services/test_lab_detector.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/auth/presentation/activation_screen.dart';
import 'package:salufit_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:salufit_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';
import 'package:salufit_app/shared/widgets/language_flag_picker.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _maybeAutoLoginForTestLab();
  }

  // Robo tests no pueden inyectar texto en TextEditingController (Flutter filtra
  // VIEW_TEXT_CHANGED de accesibilidad). Si detectamos Firebase Test Lab hacemos
  // login automático con la cuenta demo — no afecta a usuarios reales.
  Future<void> _maybeAutoLoginForTestLab() async {
    final isTestLab = await TestLabDetector.isFirebaseTestLab();
    if (!mounted || !isTestLab) return;
    debugPrint('[TestLab] Auto-login disparado para reviewer demo');
    _emailController.text = 'reviewer@centrosalufit.com';
    _passwordController.text = 'salufit';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(loginControllerProvider.notifier).login(
            'reviewer@centrosalufit.com',
            'salufit',
          );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Convierte el código de error de Firebase Auth a mensaje legible en
  /// español. Sin esto, los errores aparecían como exception genérica
  /// (o silenciosamente, ver bug 2025-05-02).
  String _readableAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Correo o contraseña incorrectos.';
        case 'invalid-email':
          return 'El correo no tiene formato válido.';
        case 'user-disabled':
          return 'Tu cuenta está deshabilitada. Contacta con el centro.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera unos minutos antes de probar de nuevo.';
        case 'network-request-failed':
          return 'Sin conexión a internet. Comprueba tu red.';
        default:
          return 'Error al iniciar sesión: ${error.message ?? error.code}';
      }
    }
    return 'Error al iniciar sesión: $error';
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final t = AppLocalizations.of(context);

    // Escuchar errores del LoginController y mostrarlos. Antes los errores
    // se silenciaban y el usuario veía el spinner desaparecer sin feedback.
    ref.listen<AsyncValue<void>>(loginControllerProvider, (prev, next) {
      if (next is AsyncError) {
        dev.log(
          '>>> [LOGIN] error: ${next.error.runtimeType} '
          '${(next.error is FirebaseAuthException) ? (next.error as FirebaseAuthException).code : ''}',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_readableAuthError(next.error)),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/login_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/login_logo.png', height: 250),
                    const SizedBox(height: 6),
                    const LanguageFlagPicker(compact: true),
                    const SizedBox(height: 14),
                    _PremiumSlogan(text: t.appSlogan),
                    const SizedBox(height: 30),
                    Semantics(
                      identifier: 'login_email_field',
                      label: 'login_email_field',
                      textField: true,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email, AutofillHints.username],
                        decoration: InputDecoration(
                          labelText: t.loginEmailLabel,
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? t.loginInvalidEmail : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      identifier: 'login_password_field',
                      label: 'login_password_field',
                      textField: true,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: t.loginPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? t.loginEmptyPassword : null,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Semantics(
                      identifier: 'login_submit_button',
                      label: 'login_submit_button',
                      button: true,
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: loginState.isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    ref.read(loginControllerProvider.notifier).login(
                                          _emailController.text.trim(),
                                          _passwordController.text.trim(),
                                        );
                                  }
                                },
                          child: loginState.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  t.loginSubmit,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(builder: (c) => const ActivationScreen()),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  t.loginFirstTime,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(builder: (c) => const ForgotPasswordScreen()),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  t.loginForgotPassword,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSlogan extends StatelessWidget {
  const _PremiumSlogan({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 0.8,
            height: 1.2,
            color: Color(0xFF454545),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF009688),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
