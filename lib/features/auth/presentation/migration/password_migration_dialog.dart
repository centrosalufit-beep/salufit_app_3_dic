import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/password_validator.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';

/// Popup obligatorio que fuerza a los usuarios existentes a actualizar
/// su contraseña a los nuevos requisitos (12+ chars, mayúscula, minúscula,
/// número). Se dispara desde MigrationGate la primera vez que el usuario
/// entra tras el despliegue.
class PasswordMigrationDialog extends ConsumerStatefulWidget {
  const PasswordMigrationDialog({super.key});

  @override
  ConsumerState<PasswordMigrationDialog> createState() =>
      _PasswordMigrationDialogState();
}

class _PasswordMigrationDialogState
    extends ConsumerState<PasswordMigrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String? _serverError;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int get _strength => PasswordValidator.strength(_passwordCtrl.text);

  Color _strengthColor(int score) {
    if (score <= 1) return Colors.red;
    if (score == 2) return Colors.orange;
    if (score == 3) return Colors.lightGreen;
    return Colors.green;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _serverError = null;
    });
    try {
      final callable = ref.read(firebaseFunctionsProvider).httpsCallable(
        'setStrongPassword',
      );
      await callable.call<Map<String, dynamic>>({
        'newPassword': _passwordCtrl.text,
      });
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverError = e.message ?? t.passwordMigrationServerError;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serverError = t.passwordUnexpectedError;
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
            const Icon(Icons.security, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.passwordMigrationDialogTitle,
                style: const TextStyle(fontSize: 18),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.passwordMigrationDialogMessage,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  _Requirement(
                    label: t.passwordRequire12Chars,
                    ok: _passwordCtrl.text.length >= 12,
                  ),
                  _Requirement(
                    label: t.passwordRequireUppercase,
                    ok: RegExp('[A-Z]').hasMatch(_passwordCtrl.text),
                  ),
                  _Requirement(
                    label: t.passwordRequireLowercase,
                    ok: RegExp('[a-z]').hasMatch(_passwordCtrl.text),
                  ),
                  _Requirement(
                    label: t.passwordRequireNumber,
                    ok: RegExp(r'\d').hasMatch(_passwordCtrl.text),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: !_showPassword,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: t.passwordMigrationLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _showPassword
                            ? t.passwordHide
                            : t.passwordShow,
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: PasswordValidator.validate,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _passwordCtrl.text.isEmpty
                              ? 0
                              : _strength / 4,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(
                            _strengthColor(_strength),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          PasswordValidator.strengthLabel(_strength),
                          style: TextStyle(
                            fontSize: 11,
                            color: _strengthColor(_strength),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: t.passwordConfirmLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v != _passwordCtrl.text
                        ? t.passwordMigrationMismatch
                        : null,
                  ),
                  if (_serverError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _serverError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading
                ? null
                : () {
                    // Cerrar sesión si el usuario no quiere migrar
                    Navigator.of(context).pop(false);
                  },
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
                : Text(t.commonSave),
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? Colors.green : Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: ok ? Colors.green.shade800 : Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
