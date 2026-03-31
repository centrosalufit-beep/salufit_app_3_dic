import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/auth/presentation/activation_screen.dart';
import 'package:salufit_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:salufit_app/features/auth/presentation/forgot_password_screen.dart';

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
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
                    const SizedBox(height: 10),
                    const _PremiumSlogan(),
                    const SizedBox(height: 35),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
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
                            : const Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            // CORRECCIÓN 1: Tipado explícito <void> para MaterialPageRoute
                            onPressed: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(builder: (c) => const ActivationScreen()),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Primera vez', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextButton(
                            // CORRECCIÓN 2: Tipado explícito <void> para MaterialPageRoute
                            onPressed: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(builder: (c) => const ForgotPasswordScreen()),
                            ),
                            child: const Text(
                              '¿Olvidaste\ncontraseña?',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
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
  const _PremiumSlogan();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 26,
              letterSpacing: 0.8,
              height: 1.2,
            ),
            children: [
              TextSpan(
                text: 'Tu salud en manos\n',
                style: TextStyle(
                  color: Color(0xFF454545),
                  fontWeight: FontWeight.w300,
                ),
              ),
              TextSpan(
                text: 'PROFESIONALES',
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontWeight: FontWeight.w900,
                  // CORRECCIÓN 3: prefer_int_literals (2 en lugar de 2.0)
                  letterSpacing: 2,
                ),
              ),
            ],
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
