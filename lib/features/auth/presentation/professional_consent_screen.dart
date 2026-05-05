import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/data/professional_consent_text.dart';

/// Pantalla bloqueante con el Acuerdo de Confidencialidad Profesional.
/// Solo se cierra cuando el usuario firma electrónicamente.
///
/// Política (decisión usuario):
///  - El profesional NO puede entrar a la app sin firmar.
///  - Tras firmar, se registra en `professional_consents/{uid}` con
///    hash SHA-256 del texto firmado, dispositivo, fecha, IP (server-side).
class ProfessionalConsentScreen extends ConsumerStatefulWidget {
  const ProfessionalConsentScreen({super.key});

  @override
  ConsumerState<ProfessionalConsentScreen> createState() =>
      _ProfessionalConsentScreenState();
}

class _ProfessionalConsentScreenState
    extends ConsumerState<ProfessionalConsentScreen> {
  final _scrollCtrl = ScrollController();
  final _dniCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  bool _hasReadEnd = false;
  bool _accept1 = false;
  bool _accept2 = false;
  bool _accept3 = false;
  bool _accept4 = false;
  bool _signing = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _dniCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasReadEnd && _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 80) {
      setState(() => _hasReadEnd = true);
    }
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;
    setState(() => _userEmail = email);
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users_app').doc(uid).get();
    if (!doc.exists || !mounted) return;
    _nombreCtrl.text = doc.data().safeString('nombreCompleto');
    final dni = doc.data().safeString('dni');
    if (dni.isNotEmpty) _dniCtrl.text = dni;
  }

  bool get _canSign =>
      _hasReadEnd &&
      _accept1 && _accept2 && _accept3 && _accept4 &&
      _dniCtrl.text.trim().length >= 8 &&
      _nombreCtrl.text.trim().length >= 5 &&
      !_signing;

  Future<void> _sign() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _signing = true);
    try {
      // Hash SHA-256 del cuerpo del documento. Si el texto cambia, el
      // hash cambia → la app exigirá re-firma (versión nueva).
      final bytes = utf8.encode(kProfessionalConsentBody);
      final hash = crypto.sha256.convert(bytes).toString();

      final db = FirebaseFirestore.instance;
      await db.collection('professional_consents').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'nombreFirmante': _nombreCtrl.text.trim(),
        'dniFirmante': _dniCtrl.text.trim().toUpperCase(),
        'version': kProfessionalConsentVersion,
        'documentTitle': kProfessionalConsentDocumentTitle,
        'bodyHashSha256': hash,
        'declaracion1Aceptada': _accept1,
        'declaracion2Aceptada': _accept2,
        'declaracion3Aceptada': _accept3,
        'declaracion4Aceptada': _accept4,
        'firmadoEn': FieldValue.serverTimestamp(),
        'firmadoEnLocalIso': DateTime.now().toIso8601String(),
        'plataforma': defaultTargetPlatformName(),
        'userAgent': 'SalufitApp',
      });

      // Audit log paralelo (consultable por admin)
      await db.collection('audit_logs').add({
        'tipo': 'PROFESSIONAL_CONSENT_SIGNED',
        'userId': user.uid,
        'metadata': {
          'version': kProfessionalConsentVersion,
          'bodyHashSha256': hash,
          'dni': _dniCtrl.text.trim().toUpperCase(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'SUCCESS',
      });

      if (!mounted) return;
      // El RoleGate detectará el cambio en professional_consents y nos
      // dejará pasar automáticamente.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Consentimiento firmado correctamente. ¡Bienvenido a Salufit!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _signing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error firmando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String defaultTargetPlatformName() {
    return Theme.of(context).platform.name;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMMM yyyy', 'es');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Sin botón de retroceso — bloqueante.
      appBar: AppBar(
        title: const Text('Acuerdo de Confidencialidad'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
            label: const Text('Salir',
                style: TextStyle(color: Colors.white70)),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Salir sin firmar'),
                  content: const Text(
                    'Si no firmas el acuerdo, no podrás usar la app. '
                    '¿Cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Volver'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              );
              if (ok ?? false) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Banner top
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border(
                      bottom: BorderSide(color: Colors.orange.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Documento legal — Lectura obligatoria',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Este acuerdo regula tu obligación de confidencialidad sobre datos '
                      'de pacientes y el uso exclusivo de los canales corporativos de '
                      'Salufit. Léelo entero, marca las 4 casillas y firma.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ],
                ),
              ),
              // Documento con scroll
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Scrollbar(
                    controller: _scrollCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      child: const SelectableText(
                        kProfessionalConsentBody,
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              // Estado de lectura
              if (!_hasReadEnd)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '⬇ Desplázate hasta el final para activar la firma',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              // Checkboxes y firma
              if (_hasReadEnd)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Declaraciones obligatorias',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _checkbox(
                        '1. He leído íntegramente este documento y comprendo todas sus cláusulas, incluida la cláusula penal de 3.000 € y el periodo de no captación de 16 meses post-baja.',
                        _accept1,
                        (v) => setState(() => _accept1 = v ?? false),
                      ),
                      _checkbox(
                        '2. Me obligo a usar EXCLUSIVAMENTE los canales corporativos de Salufit (app + WhatsApp del centro) para toda comunicación con pacientes, sin facilitar ni utilizar mis datos de contacto personales.',
                        _accept2,
                        (v) => setState(() => _accept2 = v ?? false),
                      ),
                      _checkbox(
                        '3. Asumo personalmente la responsabilidad civil y, en su caso, penal por usos indebidos de datos fuera del marco autorizado, eximiendo a Salufit de responsabilidad solidaria entre las partes.',
                        _accept3,
                        (v) => setState(() => _accept3 = v ?? false),
                      ),
                      _checkbox(
                        '4. He tenido la oportunidad real de consultar dudas con la dirección de Salufit y, en su caso, con asesor propio, antes de firmar.',
                        _accept4,
                        (v) => setState(() => _accept4 = v ?? false),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nombreCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre y apellidos',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _dniCtrl,
                              decoration: const InputDecoration(
                                labelText: 'DNI / NIE',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(12),
                              ],
                              textCapitalization:
                                  TextCapitalization.characters,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Vas a firmar como ${_userEmail ?? "(usuario actual)"} el día ${fmt.format(DateTime.now())}.\n'
                          'Tu firma quedará registrada con hash criptográfico SHA-256 del documento, '
                          'fecha, dispositivo y dirección IP para fines de auditoría.',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _canSign ? _sign : null,
                          icon: _signing
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.draw),
                          label: const Text('FIRMAR Y ACEPTAR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _checkbox(String text, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      value: value,
      onChanged: onChanged,
      title: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
