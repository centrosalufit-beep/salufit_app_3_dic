import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/auth/data/auth_repository.dart';
import 'package:salufit_app/features/auth/presentation/auth_wrapper.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  ConsumerState<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends ConsumerState<TermsAcceptanceScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _termsRead = false;
  bool _privacyRead = false;
  bool _isLoading = false;

  final String _urlPrivacidad = AppConfig.urlPrivacidad;
  final String _urlTerminos = AppConfig.urlTerminos;

  Future<void> _openWeb(String url, {required bool isTerms}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        setState(() {
          if (isTerms) {
            _termsRead = true;
          } else {
            _privacyRead = true;
          }
        });
      }
    }
  }

  Future<void> _contactClinic() async {
    final uri = Uri.parse('tel:${AppConfig.telefonoSoporte.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleAcceptance() async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    final t = AppLocalizations.of(context);

    setState(() => _isLoading = true);
    try {
      final metadata = {
        'platform': defaultTargetPlatform.toString(),
        'deviceLabel': kIsWeb ? 'Web Browser' : Platform.operatingSystem,
        'legalVersion': AppConfig.termsVersionActual,
      };

      await ref.read(authRepositoryProvider).acceptTermsWithMetadata(uid, metadata);

      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthWrapper()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.termsErrorRetry),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final allChecked = _termsAccepted && _privacyAccepted;
    final allRead = _termsRead && _privacyRead;

    return SalufitScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.verified_user_rounded, size: 70, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              t.termsValidationTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Text(
              t.termsValidationSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_services_outlined,
                      color: Colors.amber.shade800, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.termsMedicalDisclaimer,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.amber.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildLegalButton(
              label: t.termsReadTermsButton,
              url: _urlTerminos,
              isTerms: true,
              wasRead: _termsRead,
            ),
            const SizedBox(height: 10),
            _buildLegalButton(
              label: t.termsReadPrivacyButton,
              url: _urlPrivacidad,
              isTerms: false,
              wasRead: _privacyRead,
            ),
            const SizedBox(height: 30),
            _buildCheckRow(
              text: t.termsAcceptTermsCheckbox,
              value: _termsAccepted,
              enabled: _termsRead,
              onChanged: (v) => setState(() => _termsAccepted = v!),
            ),
            _buildCheckRow(
              text: t.termsAcceptPrivacyCheckbox,
              value: _privacyAccepted,
              enabled: _privacyRead,
              onChanged: (v) => setState(() => _privacyAccepted = v!),
            ),
            if (!allRead) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.termsReadFirstWarning,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: allChecked ? 0.0 : 1.0,
              child: Column(
                children: [
                  Text(
                    t.termsRequiredBoth,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.termsContactClinicLine,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _contactClinic,
                    child: Text(
                      t.termsSupportLine(AppConfig.telefonoSoporte),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: allChecked ? _handleAcceptance : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  t.termsConfirmAccess,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: Text(
                  t.termsExit,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegalButton({
    required String label,
    required String url,
    required bool isTerms,
    required bool wasRead,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _openWeb(url, isTerms: isTerms),
      icon: Icon(
        wasRead ? Icons.check_circle : Icons.open_in_new,
        size: 18,
        color: wasRead ? Colors.green : AppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: wasRead ? Colors.green.shade700 : AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: wasRead ? Colors.green.shade300 : AppColors.primary.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCheckRow({
    required String text,
    required bool value,
    required bool enabled,
    required ValueChanged<bool?> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
