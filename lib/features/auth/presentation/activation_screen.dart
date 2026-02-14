import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/presentation/activation_screen_helper.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _historyController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _procesoActivacion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final idH = _historyController.text.trim().padLeft(6, '0');

    try {
      dev.log('>>> [ACTIVACION] Verificando estado para: $email');

      // 1. SMART CHECK: ¿Ya existe en la colección de usuarios activos?
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        dev.log('>>> [ACTIVACION] Usuario ya registrado. Disparando Smart-Popup.');
        if (!mounted) return;
        setState(() => _isLoading = false);
        ActivationUIHelper.showAlreadyRegisteredDialog(context, ref, email);
        return;
      }

      // 2. Validar en colección legacy 'legacy_import'
      final doc = await FirebaseFirestore.instance
          .collection('legacy_import')
          .doc(idH)
          .get();

      if (!doc.exists || doc.data()?['email'] != email) {
        throw Exception('Los datos no coinciden con nuestra base de datos.');
      }

      // 3. Si ya estaba activado en legacy pero no en users, algo falló en la migración
      if (doc.data()?['activado'] == true) {
        dev.log('>>> [ACTIVACION] Ficha marcada como activada en legacy. Re-enviando reset.');
      }

      // 4. Enviar email usando nuestro servicio auditado (con idioma ES)
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);

      if (!mounted) return;
      _showSuccessDialog(email);
    } catch (e) {
      dev.log('>>> [ERROR ACTIVACION] $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String email) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¡Identidad Verificada!'),
        content: Text(
          'Hemos enviado un enlace a $email.\n\nÚsalo para crear tu contraseña y acceder por primera vez.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
            onPressed: () {
              Navigator.pop(ctx); // Cierra dialog
              Navigator.pop(context); // Vuelve al Login
            },
            child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const salufitTeal = Color(0xFF009688);

    return SalufitScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activar Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: salufitTeal,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          children: [
            const Icon(Icons.verified_user_outlined, size: 80, color: salufitTeal),
            const SizedBox(height: 20),
            const Text(
              'Introduce tus datos para vincular tu ficha médica con la App.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _historyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nº Historia',
                prefixIcon: const Icon(Icons.assignment_ind_outlined, color: salufitTeal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined, color: salufitTeal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido' : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: salufitTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _procesoActivacion,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'VERIFICAR MI IDENTIDAD',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
