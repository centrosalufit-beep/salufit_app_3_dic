import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/auth/presentation/activation_screen_helper.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';
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
    final t = AppLocalizations.of(context);

    final email = _emailController.text.trim().toLowerCase();
    final idH = _historyController.text.trim().padLeft(6, '0');

    try {
      dev.log('>>> [ACTIVACION] Verificando estado via Cloud Function');

      // El plugin cloud_functions de Flutter NO funciona en Windows desktop
      // (MethodChannel no implementado): falla con `firebase_functions/unknown`.
      // Usamos la versión HTTP (`checkAccountStatusHttp`) en Windows y la
      // versión `onCall` en mobile/web/macOS donde el plugin sí funciona.
      final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
      final String? status;
      if (isWindows) {
        final url = Uri.parse(
          'https://us-central1-salufitnewapp.cloudfunctions.net/checkAccountStatusHttp',
        );
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'historyId': idH}),
        );
        if (response.statusCode == 429) {
          throw Exception(t.activationServerError);
        }
        if (response.statusCode != 200) {
          final data = response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body) as Map<String, dynamic>;
          final err = (data['error'] as String?) ?? t.activationServerError;
          throw Exception(err);
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        status = data['status'] as String?;
      } else {
        final result = await ref
            .read(firebaseFunctionsProvider)
            .httpsCallable('checkAccountStatus')
            .call<Map<String, dynamic>>({
          'email': email,
          'historyId': idH,
        });
        status = result.data['status'] as String?;
      }

      if (status == 'ALREADY_REGISTERED') {
        dev.log('>>> [ACTIVACION] Usuario ya registrado. Disparando Smart-Popup.');
        if (!mounted) return;
        setState(() => _isLoading = false);
        ActivationUIHelper.showAlreadyRegisteredDialog(context, ref, email);
        return;
      }

      if (status == 'NOT_FOUND') {
        throw Exception(t.activationDataMismatch);
      }

      await ref.read(authServiceProvider).sendPasswordResetEmail(email);

      if (!mounted) return;
      _showSuccessDialog(email);
    } catch (e) {
      dev.log('>>> [ERROR ACTIVACION] ${e.runtimeType}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('permission-denied')
                ? t.activationServerError
                : e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String email) {
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(t.activationVerifiedTitle),
        content: Text(t.activationVerifiedMessage(email)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              t.commonGotIt.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SalufitScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          t.activationTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          children: [
            const Icon(Icons.verified_user_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              t.activationLinkPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _historyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.activationHistoryNumber,
                prefixIcon: const Icon(
                  Icons.assignment_ind_outlined,
                  color: AppColors.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? t.commonRequired : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: t.loginEmailLabel,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  (value == null || !value.contains('@')) ? t.loginInvalidEmail : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _procesoActivacion,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        t.activationVerifyIdentity,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
