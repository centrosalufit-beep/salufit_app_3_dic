import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/theme/app_colors.dart';

/// Popup obligatorio de consentimiento granular RGPD.
///
/// Permite al usuario aceptar/rechazar cada finalidad por separado:
/// - Datos médicos (obligatorio para usar la app)
/// - Comunicaciones de marketing (opcional)
/// - Perfilado analítico (opcional)
///
/// El consentimiento obligatorio siempre es "aceptar o salir". Los demás
/// se guardan con la decisión del usuario para respetar el derecho a
/// retirar el consentimiento en cualquier momento (RGPD Art. 7).
class GranularConsentDialog extends StatefulWidget {
  const GranularConsentDialog({super.key});

  @override
  State<GranularConsentDialog> createState() => _GranularConsentDialogState();
}

class _GranularConsentDialogState extends State<GranularConsentDialog> {
  bool _medicalData = false;
  bool _marketingConsent = false;
  bool _analyticsConsent = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_medicalData) {
      setState(() => _error =
          'El tratamiento de datos médicos es necesario para usar la app.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Sesión no válida');

      await FirebaseFirestore.instance.collection('users_app').doc(uid).update({
        'consentVersion': AppConfig.consentVersionActual,
        'consentDate': FieldValue.serverTimestamp(),
        'consentGranular': {
          'medicalData': _medicalData,
          'marketing': _marketingConsent,
          'analytics': _analyticsConsent,
        },
      });

      // Auditoría del consentimiento (obligatorio RGPD Art. 7.1)
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'tipo': 'CONSENT_GRANTED',
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'version': AppConfig.consentVersionActual,
          'medicalData': _medicalData,
          'marketing': _marketingConsent,
          'analytics': _analyticsConsent,
        },
        'status': 'SUCCESS',
      });

      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo guardar. Revisa tu conexión.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Tu privacidad')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hemos actualizado nuestra política de privacidad. '
                  'Por favor revisa y selecciona qué permites que hagamos '
                  'con tus datos. Puedes cambiar estas preferencias en '
                  'cualquier momento desde tu perfil.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                _ConsentTile(
                  title: 'Datos médicos e historia clínica',
                  subtitle:
                      'Obligatorio. Necesario para ofrecerte el servicio '
                      'médico y deportivo del centro.',
                  required: true,
                  value: _medicalData,
                  onChanged: (v) =>
                      setState(() => _medicalData = v ?? false),
                ),
                const SizedBox(height: 8),
                _ConsentTile(
                  title: 'Comunicaciones comerciales',
                  subtitle:
                      'Opcional. Recibir información sobre ofertas, eventos '
                      'y novedades del centro por email.',
                  required: false,
                  value: _marketingConsent,
                  onChanged: (v) =>
                      setState(() => _marketingConsent = v ?? false),
                ),
                const SizedBox(height: 8),
                _ConsentTile(
                  title: 'Analítica de uso de la app',
                  subtitle:
                      'Opcional. Ayúdanos a mejorar la app analizando cómo '
                      'la usas (no incluye datos médicos).',
                  required: false,
                  value: _analyticsConsent,
                  onChanged: (v) =>
                      setState(() => _analyticsConsent = v ?? false),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Política completa en ${AppConfig.urlPrivacidad}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Salir'),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Guardar preferencias'),
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.subtitle,
    required this.required,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool required;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? AppColors.primary.withValues(alpha: 0.05) : null,
        border: Border.all(
          color: value ? AppColors.primary : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OBLIGATORIO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
