import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';

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
class GranularConsentDialog extends ConsumerStatefulWidget {
  const GranularConsentDialog({super.key});

  @override
  ConsumerState<GranularConsentDialog> createState() =>
      _GranularConsentDialogState();
}

class _GranularConsentDialogState
    extends ConsumerState<GranularConsentDialog> {
  bool _medicalData = false;
  bool _marketingConsent = false;
  bool _analyticsConsent = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    if (!_medicalData) {
      setState(() => _error = t.consentMedicalRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception(t.consentSessionInvalid);

      final db = ref.read(firebaseFirestoreProvider);
      await db.collection('users_app').doc(uid).update({
        'consentVersion': AppConfig.consentVersionActual,
        'consentDate': FieldValue.serverTimestamp(),
        'consentGranular': {
          'medicalData': _medicalData,
          'marketing': _marketingConsent,
          'analytics': _analyticsConsent,
        },
      });

      // Auditoría del consentimiento (obligatorio RGPD Art. 7.1)
      await db.collection('audit_logs').add({
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
        _error = AppLocalizations.of(context).consentSaveError;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.consentPrivacyTitle,
                style: const TextStyle(fontSize: 18),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.consentUpdatedMessage,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                _ConsentTile(
                  title: t.consentMedicalShort,
                  subtitle: t.consentMedicalLongDesc,
                  required: true,
                  requiredLabel: t.consentRequiredBadge,
                  value: _medicalData,
                  onChanged: (v) =>
                      setState(() => _medicalData = v ?? false),
                ),
                const SizedBox(height: 8),
                _ConsentTile(
                  title: t.consentMarketingShort,
                  subtitle: t.consentMarketingLongDesc,
                  required: false,
                  requiredLabel: t.consentRequiredBadge,
                  value: _marketingConsent,
                  onChanged: (v) =>
                      setState(() => _marketingConsent = v ?? false),
                ),
                const SizedBox(height: 8),
                _ConsentTile(
                  title: t.consentAnalyticsShort,
                  subtitle: t.consentAnalyticsLongDesc,
                  required: false,
                  requiredLabel: t.consentRequiredBadge,
                  value: _analyticsConsent,
                  onChanged: (v) =>
                      setState(() => _analyticsConsent = v ?? false),
                ),
                const SizedBox(height: 16),
                Text(
                  t.consentFullPolicyLink(AppConfig.urlPrivacidad),
                  style: const TextStyle(
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
            child: Text(t.termsExit),
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
                : Text(t.consentSubmitPreferences),
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
    required this.requiredLabel,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool required;
  final String requiredLabel;
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (required)
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
                          requiredLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
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
