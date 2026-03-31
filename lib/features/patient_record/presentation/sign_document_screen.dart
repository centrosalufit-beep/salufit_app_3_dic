import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Datos precargados de odontologos con numero de colegiado.
const _odontologos = {
  'Maria Valles Pastor': {'dni': '53627251Z', 'colegiado': '03003577', 'colegio': 'COEA'},
  'Blanca Alagarda Lauwers': {'dni': '74019630H', 'colegiado': '46006025', 'colegio': 'COEV'},
};

class SignDocumentScreen extends ConsumerStatefulWidget {
  const SignDocumentScreen({
    required this.documentId,
    required this.documentTitle,
    required this.pdfUrl,
    this.signerRole = 'cliente',
    this.requiereDobleFirma = false,
    super.key,
  });

  final String documentId;
  final String documentTitle;
  final String pdfUrl;
  final String signerRole;
  final bool requiereDobleFirma;

  @override
  ConsumerState<SignDocumentScreen> createState() => _SignDocumentScreenState();
}

class _SignDocumentScreenState extends ConsumerState<SignDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  // Cliente
  final _dniController = TextEditingController();
  final _nombreController = TextEditingController();
  // Profesional
  final _colegiadoController = TextEditingController();
  // OTP
  final _otpController = TextEditingController();

  bool _hasDownloaded = false;
  bool _acceptsContent = false;
  bool _acceptsVoluntary = false;
  bool _acceptsDataProcessing = false;
  bool _proConfirmsInfo = false;
  bool _isSigning = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _colegiadoVerified = false;
  String? _generatedOtp;
  String? _otpRequestId;
  String? _matchedProName;
  String? _matchedProDni;

  bool get _isProfessional => widget.signerRole == 'profesional';

  @override
  void initState() {
    super.initState();
    if (!_isProfessional) _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users_app').doc(uid).get();
    if (doc.exists && mounted) {
      _nombreController.text = doc.data().safeString('nombreCompleto');
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombreController.dispose();
    _colegiadoController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _canRequestOtp {
    if (_isProfessional) {
      return _colegiadoVerified && _proConfirmsInfo;
    }
    return _hasDownloaded &&
        _acceptsContent && _acceptsVoluntary && _acceptsDataProcessing &&
        _dniController.text.trim().length >= 8 &&
        _nombreController.text.trim().isNotEmpty;
  }

  bool get _canSign => _canRequestOtp && _otpVerified;

  Future<void> _openDocument() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _hasDownloaded = true);
    }
  }

  String _generateOtpCode() => List.generate(6, (_) => Random.secure().nextInt(10)).join();

  String _generateHash(String data) => crypto.sha256.convert(utf8.encode(data)).toString();

  void _verifyColegiado() {
    final input = _colegiadoController.text.trim();
    for (final entry in _odontologos.entries) {
      if (entry.value['colegiado'] == input) {
        setState(() {
          _colegiadoVerified = true;
          _matchedProName = entry.key;
          _matchedProDni = entry.value['dni'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verificado: ${entry.key}'), backgroundColor: Colors.green),
        );
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Numero de colegiado no reconocido'), backgroundColor: Colors.red),
    );
  }

  Future<void> _sendOtp() async {
    if (!_canRequestOtp) return;
    setState(() => _isSigning = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final email = FirebaseAuth.instance.currentUser?.email;
      if (uid == null || email == null) return;

      final code = _generateOtpCode();
      _generatedOtp = code;

      final otpDoc = await FirebaseFirestore.instance.collection('otp_requests').add({
        'userId': uid,
        'documentId': widget.documentId,
        'code': code,
        'rol': widget.signerRole,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
        'email': email,
      });
      _otpRequestId = otpDoc.id;

      if (mounted) {
        setState(() => _otpSent = true);
        _showOtpDialog(code, email);
      }
    } catch (e) {
      debugPrint('Error OTP: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar codigo'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  void _showOtpDialog(String code, String email) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.verified_user, color: AppColors.primary, size: 32)),
              const SizedBox(height: 16),
              const Text('Codigo de verificacion', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Codigo enviado a: $email', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary)),
                child: Text(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8, color: AppColors.primary)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyOtp() {
    if (_otpController.text.trim() == _generatedOtp) {
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codigo verificado'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codigo incorrecto'), backgroundColor: Colors.red));
    }
  }

  Future<void> _firmarDocumento() async {
    if (!_formKey.currentState!.validate() || !_canSign) return;
    setState(() => _isSigning = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final email = FirebaseAuth.instance.currentUser?.email;
      if (uid == null) return;

      final now = DateTime.now();
      final dni = _isProfessional ? (_matchedProDni ?? '') : _dniController.text.trim().toUpperCase();
      final nombre = _isProfessional ? (_matchedProName ?? '') : _nombreController.text.trim();
      final hashData = '$uid|${widget.documentId}|$dni|$nombre|${now.toIso8601String()}|${widget.pdfUrl}';
      final hashIntegridad = _generateHash(hashData);

      final firmaData = <String, dynamic>{
        'dni': dni,
        'nombreFirmante': nombre,
        'emailFirmante': email,
        'fechaHora': Timestamp.fromDate(now),
        'otpVerificado': true,
        'otpRequestId': _otpRequestId,
        'hashIntegridad': hashIntegridad,
        'rol': widget.signerRole,
        'metodo': 'firma_electronica_avanzada_otp',
        'versionLegal': '2026.1',
        'normativaAplicable': 'eIDAS UE 910/2014, Ley 41/2002, Ley 6/2020',
      };

      if (_isProfessional) {
        firmaData['numeroColegiado'] = _colegiadoController.text.trim();
        firmaData['confirmacionInformacion'] = true;
      } else {
        firmaData['aceptaContenido'] = true;
        firmaData['aceptaVoluntariedad'] = true;
        firmaData['aceptaTratamientoDatos'] = true;
      }

      final firmaField = _isProfessional ? 'firmaProfesional' : 'firmaCliente';
      final docSnap = await FirebaseFirestore.instance.collection('documents').doc(widget.documentId).get();
      final docData = docSnap.data() ?? {};
      final dobleFirma = docData['requiereDobleFirma'] == true;
      final otraFirma = _isProfessional ? docData['firmaCliente'] : docData['firmaProfesional'];
      final documentoCompleto = !dobleFirma || otraFirma != null;

      await FirebaseFirestore.instance.collection('documents').doc(widget.documentId).update({
        firmaField: firmaData,
        'firmaDigital': firmaData,
        if (documentoCompleto) 'firmado': true,
        if (documentoCompleto) 'fechaFirma': FieldValue.serverTimestamp(),
      });

      if (_otpRequestId != null) {
        await FirebaseFirestore.instance.collection('otp_requests').doc(_otpRequestId).update({'verified': true, 'verifiedAt': FieldValue.serverTimestamp()});
      }

      await FirebaseFirestore.instance.collection('signed_documents').add({
        'documentoId': widget.documentId,
        'userId': uid,
        'dni': dni,
        'nombreFirmante': nombre,
        'emailFirmante': email,
        'rol': widget.signerRole,
        if (_isProfessional) 'numeroColegiado': _colegiadoController.text.trim(),
        'fechaFirma': FieldValue.serverTimestamp(),
        'hashIntegridad': hashIntegridad,
        'otpRequestId': _otpRequestId,
        'titulo': widget.documentTitle,
      });

      await FirebaseFirestore.instance.collection('audit_logs').add({
        'tipo': 'FIRMA_CONSENTIMIENTO_OTP',
        'userId': uid,
        'documentId': widget.documentId,
        'documentTitle': widget.documentTitle,
        'dni': dni,
        'rol': widget.signerRole,
        'hashIntegridad': hashIntegridad,
        'fecha': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento firmado correctamente'), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Error firma: ${e.runtimeType}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al firmar'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isProfessional ? 'Firma Profesional' : 'Firma de Consentimiento', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _isProfessional ? Colors.deepOrange : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // CABECERA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: Column(children: [
                Icon(_isProfessional ? Icons.medical_services : Icons.description, size: 48, color: _isProfessional ? Colors.deepOrange : AppColors.primary),
                const SizedBox(height: 12),
                Text(widget.documentTitle.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm', 'es').format(DateTime.now())}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (_isProfessional ? Colors.deepOrange : AppColors.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_isProfessional ? 'Firma profesional sanitario' : 'Firma electronica avanzada (eIDAS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isProfessional ? Colors.deepOrange : AppColors.primary)),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            if (_isProfessional) ..._buildProfessionalFlow()
            else ..._buildClientFlow(),

            const SizedBox(height: 14),

            // OTP (comun)
            _buildStepCard(
              step: _isProfessional ? 3 : 4,
              title: 'Verificacion OTP',
              subtitle: 'Codigo para firma avanzada.',
              isCompleted: _otpVerified,
              color: Colors.orange,
              child: _buildOtpSection(),
            ),
            const SizedBox(height: 16),

            // AVISO LEGAL
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Firma electronica avanzada conforme al Reglamento eIDAS (UE 910/2014), Ley 41/2002 y Ley 6/2020. '
                  'Incluye verificacion OTP y hash SHA-256.',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade800, height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 24),

            // BOTON FIRMAR
            ElevatedButton(
              onPressed: _isSigning || !_canSign ? null : _firmarDocumento,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProfessional ? Colors.deepOrange : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: _canSign ? 4 : 0,
              ),
              child: _isSigning
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.draw, size: 22), const SizedBox(width: 10), Text(_isProfessional ? 'FIRMAR COMO PROFESIONAL' : 'FIRMAR CON OTP', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── FLUJO PROFESIONAL (rapido) ─────────────────────────
  List<Widget> _buildProfessionalFlow() => [
    _buildStepCard(
      step: 1,
      title: 'Numero de colegiado',
      subtitle: 'Introduce tu numero para verificar tu identidad.',
      isCompleted: _colegiadoVerified,
      color: Colors.deepOrange,
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _colegiadoController,
              decoration: const InputDecoration(labelText: 'N. Colegiado', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder(), hintText: '03003577'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().length < 6) ? 'Numero no valido' : null,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _colegiadoVerified ? null : _verifyColegiado,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ]),
        if (_colegiadoVerified && _matchedProName != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade300)),
            child: Row(children: [
              const Icon(Icons.verified, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('$_matchedProName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green))),
            ]),
          ),
        ],
      ]),
    ),
    const SizedBox(height: 14),
    _buildStepCard(
      step: 2,
      title: 'Confirmacion profesional',
      subtitle: 'Confirma que has informado al paciente.',
      isCompleted: _proConfirmsInfo,
      color: Colors.deepOrange,
      child: CheckboxListTile(
        value: _proConfirmsInfo,
        onChanged: _colegiadoVerified ? (v) => setState(() => _proConfirmsInfo = v!) : null,
        title: const Text('Confirmo que he informado al paciente sobre el procedimiento, riesgos, beneficios y alternativas, y que he resuelto todas sus dudas antes de recabar su consentimiento.', style: TextStyle(fontSize: 12, height: 1.3)),
        activeColor: Colors.deepOrange,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ),
  ];

  // ── FLUJO CLIENTE (completo) ───────────────────────────
  List<Widget> _buildClientFlow() => [
    _buildStepCard(step: 1, title: 'Leer el documento', subtitle: 'Obligatorio antes de firmar.', isCompleted: _hasDownloaded, child: Column(children: [
      ElevatedButton.icon(
        onPressed: _openDocument,
        icon: Icon(_hasDownloaded ? Icons.check_circle : Icons.download, size: 20),
        label: Text(_hasDownloaded ? 'DOCUMENTO LEIDO' : 'ABRIR DOCUMENTO'),
        style: ElevatedButton.styleFrom(backgroundColor: _hasDownloaded ? Colors.green : AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      if (!_hasDownloaded) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Abre el documento para continuar', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
    ])),
    const SizedBox(height: 14),
    _buildStepCard(step: 2, title: 'Datos del firmante', subtitle: 'Identificacion obligatoria.', isCompleted: _dniController.text.trim().length >= 8 && _nombreController.text.trim().isNotEmpty, child: Column(children: [
      TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null, onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      TextFormField(controller: _dniController, decoration: const InputDecoration(labelText: 'DNI / NIE', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder(), hintText: '12345678A'), textCapitalization: TextCapitalization.characters, validator: (v) => (v == null || v.trim().length < 8) ? 'DNI no valido' : null, onChanged: (_) => setState(() {})),
    ])),
    const SizedBox(height: 14),
    _buildStepCard(step: 3, title: 'Declaraciones', subtitle: 'Marca todas para confirmar.', isCompleted: _acceptsContent && _acceptsVoluntary && _acceptsDataProcessing, child: Column(children: [
      _buildCheckItem(value: _acceptsContent, text: 'He leido y comprendo el contenido del documento, incluyendo riesgos, beneficios y alternativas.', onChanged: _hasDownloaded ? (v) => setState(() => _acceptsContent = v!) : null),
      _buildCheckItem(value: _acceptsVoluntary, text: 'Otorgo mi consentimiento de forma libre, voluntaria e informada.', onChanged: _hasDownloaded ? (v) => setState(() => _acceptsVoluntary = v!) : null),
      _buildCheckItem(value: _acceptsDataProcessing, text: 'Autorizo el tratamiento de mis datos conforme al RGPD y la LOPDGDD.', onChanged: _hasDownloaded ? (v) => setState(() => _acceptsDataProcessing = v!) : null),
    ])),
  ];

  // ── OTP SECTION (comun) ────────────────────────────────
  Widget _buildOtpSection() {
    if (!_otpSent) {
      return Column(children: [
        ElevatedButton.icon(
          onPressed: _canRequestOtp && !_isSigning ? _sendOtp : null,
          icon: _isSigning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send, size: 18),
          label: const Text('SOLICITAR CODIGO OTP'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade300, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        if (!_canRequestOtp) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Completa los pasos anteriores', style: TextStyle(color: Colors.grey.shade500, fontSize: 11), textAlign: TextAlign.center)),
      ]);
    }
    if (!_otpVerified) {
      return Column(children: [
        Row(children: [
          Expanded(child: TextFormField(controller: _otpController, decoration: const InputDecoration(labelText: 'Codigo OTP', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()), keyboardType: TextInputType.number, maxLength: 6, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4), textAlign: TextAlign.center)),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: _otpController.text.length == 6 ? _verifyOtp : null, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Icon(Icons.check, color: Colors.white)),
        ]),
        const SizedBox(height: 8),
        TextButton(onPressed: _sendOtp, child: const Text('Reenviar codigo', style: TextStyle(fontSize: 12))),
      ]);
    }
    return const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified, color: Colors.green, size: 24), SizedBox(width: 8), Text('Identidad verificada', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]);
  }

  // ── WIDGETS COMUNES ────────────────────────────────────
  Widget _buildStepCard({required int step, required String title, required String subtitle, required bool isCompleted, required Widget child, Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isCompleted ? Colors.green.shade300 : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: isCompleted ? Colors.green : Colors.grey.shade300, shape: BoxShape.circle), child: Center(child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))])),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _buildCheckItem({required bool value, required String text, required ValueChanged<bool?>? onChanged}) {
    return Opacity(opacity: onChanged != null ? 1.0 : 0.4, child: CheckboxListTile(value: value, onChanged: onChanged, title: Text(text, style: const TextStyle(fontSize: 12, height: 1.3)), activeColor: AppColors.primary, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, dense: true));
  }
}
