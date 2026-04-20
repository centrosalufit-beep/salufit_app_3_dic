import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/theme/app_colors.dart';

/// Popup obligatorio que solicita la fecha de nacimiento para verificar
/// mayoría de edad (14 años LOPDGDD España / 16 años RGPD UE base).
///
/// Si el usuario es menor de la edad mínima, se bloquea su acceso y se
/// le pide que un padre/madre/tutor contacte con el centro.
class DateOfBirthDialog extends StatefulWidget {
  const DateOfBirthDialog({super.key});

  @override
  State<DateOfBirthDialog> createState() => _DateOfBirthDialogState();
}

class _DateOfBirthDialogState extends State<DateOfBirthDialog> {
  DateTime? _selected;
  bool _loading = false;
  String? _error;
  bool _requiresParentalConsent = false;

  int _yearsOld(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selected ?? DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;
    setState(() {
      _selected = picked;
      _error = null;
      final age = _yearsOld(picked);
      _requiresParentalConsent = age < AppConfig.edadMinimaRgpd;
    });
  }

  Future<void> _submit() async {
    if (_selected == null) {
      setState(() => _error = 'Selecciona una fecha');
      return;
    }
    final age = _yearsOld(_selected!);
    if (age < AppConfig.edadMinima) {
      setState(
        () =>
            _error = 'La edad mínima para usar la app es ${AppConfig.edadMinima} años.',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Sesión no válida');

      await FirebaseFirestore.instance.collection('users_app').doc(uid).update({
        'dateOfBirth': Timestamp.fromDate(_selected!),
        'dateOfBirthSet': true,
        'ageAtRegistration': age,
        'requiresParentalConsent': _requiresParentalConsent,
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
            Icon(Icons.cake, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Confirma tu edad')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para cumplir con la normativa de protección de datos '
                'necesitamos tu fecha de nacimiento.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _loading ? null : _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selected == null
                              ? 'Selecciona fecha'
                              : '${_selected!.day.toString().padLeft(2, '0')}/'
                                  '${_selected!.month.toString().padLeft(2, '0')}/'
                                  '${_selected!.year}',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selected == null
                                ? Colors.grey.shade700
                                : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
              if (_requiresParentalConsent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Al ser menor, un padre/madre/tutor debe dar su '
                          'consentimiento expreso. Lo confirmaremos por '
                          'teléfono antes de activar tu cuenta completa.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                : const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
