import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/presentation/activation_screen.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        var message = 'Error al iniciar sesión';
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('user-not-found')) {
          message = 'No existe una cuenta con este correo.';
        } else if (errorStr.contains('wrong-password')) {
          message = 'La contraseña es incorrecta.';
        } else if (errorStr.contains('invalid-credential')) {
          message = 'Credenciales inválidas.';
        } else if (errorStr.contains('too-many-requests')) {
          message = 'Cuenta bloqueada temporalmente.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onPrimeraVezPressed() {
    Navigator.push(
      context,
      MaterialPageRoute<ActivationScreen>(
        builder: (context) => const ActivationScreen(),
      ),
    );
  }

  Future<void> _onForgotPasswordPressed() async {
    final emailResetController =
        TextEditingController(text: _emailController.text);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Introduce tu correo y te enviaremos un enlace para generar una nueva contraseña.',
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ENVIAR ENLACE'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      if (!mounted) return;
      final email = emailResetController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, introduce un correo válido.'),
          ),
        );
        return;
      }

      try {
        dev.log('>>> [AUDITORIA] Intentando enviar correo de reset a: $email');
        await ref.read(authServiceProvider).sendPasswordResetEmail(email);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Si el correo está registrado, recibirás un enlace en breve.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } catch (e) {
        dev.log('>>> [ERROR AUTH] Error al enviar reset: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo procesar la solicitud.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const salufitTeal = Color(0xFF009688);

    return SalufitScaffold(
      backgroundColor: Colors.white,
      showWatermark: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/login_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[300]),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withAlpha(13),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/login_logo.png',
                      height: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const SizedBox(height: 300),
                    ),
                    const SizedBox(height: 15),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Tu salud en manos profesionales',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(0, 0, 0, 0.87),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: salufitTeal,
                          size: 26,
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha(230),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withAlpha(77),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: salufitTeal, width: 2),
                        ),
                      ),
                      validator: (value) => (value == null ||
                              value.isEmpty ||
                              !value.contains('@'))
                          ? 'Correo inválido'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: salufitTeal,
                          size: 26,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          color: Colors.grey,
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha(230),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withAlpha(77),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: salufitTeal, width: 2),
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: salufitTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _onPrimeraVezPressed,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: salufitTeal,
                              backgroundColor:
                                  Colors.white.withAlpha(178),
                              side: const BorderSide(
                                color: salufitTeal,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Primera vez',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextButton(
                            onPressed:
                                _isLoading ? null : _onForgotPasswordPressed,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF424242),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              '¿Olvidaste\ncontraseña?',
                              textAlign: TextAlign.center,
                              style: TextStyle(height: 1.1),
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
