import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SignDocumentScreen extends StatefulWidget {
  const SignDocumentScreen({
    required this.userId,
    required this.documentId,
    required this.documentTitle,
    super.key,
    this.consentOptions = const <String>[],
  });
  final String userId;
  final String documentId;
  final String documentTitle;
  final List<String> consentOptions;

  @override
  State<SignDocumentScreen> createState() => _SignDocumentScreenState();
}

class _SignDocumentScreenState extends State<SignDocumentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _cpController = TextEditingController();
  final TextEditingController _localidadController = TextEditingController();

  final TextEditingController _minorNameController = TextEditingController();
  final TextEditingController _minorDniController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = true;
  bool _isSendingEmail = false;
  bool _aceptadoCondiciones = false;
  bool _haAbiertoDocumento = false;
  bool _isMinor = false;
  String? _pdfUrl;

  final Map<String, bool> _consentSelections = <String, bool>{};

  final String _enviarOtpUrl =
      'https://us-central1-salufitnewapp.cloudfunctions.net/enviarCodigoOTP';
  final String _verificarOtpUrl =
      'https://us-central1-salufitnewapp.cloudfunctions.net/verificarCodigoOTP';

  @override
  void initState() {
    super.initState();
    _initConsentMap();
    _cargarDatosIniciales();
  }

  void _initConsentMap() {
    for (final option in widget.consentOptions) {
      _consentSelections[option] = false;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        _nombreController.text = (data['nombreCompleto'] as String?) ?? '';
        _dniController.text = (data['dni'] as String?) ?? '';
        _direccionController.text = (data['direccion'] as String?) ?? '';
        _cpController.text = (data['cp'] as String?) ?? '';
        _localidadController.text = (data['localidad'] as String?) ?? '';
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .doc(widget.documentId)
          .get();
      if (docSnapshot.exists) {
        final docData = docSnapshot.data()!;
        setState(() {
          _pdfUrl = docData['urlPdf'] as String?;
        });
      }
    } on Exception catch (e) {
      debugPrint('Error cargando datos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken();
  }

  Future<void> _solicitarCodigo() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los campos obligatorios en rojo')),
      );
      return;
    }

    if (!_haAbiertoDocumento) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'POR FAVOR: Abre y lee el documento PDF antes de firmar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_aceptadoCondiciones) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar las condiciones')),
      );
      return;
    }

    setState(() {
      _isSendingEmail = true;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await http.post(
        Uri.parse(_enviarOtpUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'userId': widget.userId,
          'documentId': widget.documentId,
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código de seguridad enviado a tu email'),
            backgroundColor: Colors.green,
          ),
        );
        _mostrarDialogoOTP();
      } else {
        // CORRECCIÓN: Casting explícito para evitar dynamic
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          (data['error'] as String?) ?? 'Error desconocido del servidor',
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }

  Future<void> _validarFirma() async {
    final codigo = _otpController.text.trim();
    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El código debe tener 6 dígitos')),
      );
      return;
    }

    Navigator.pop(context);
    setState(() {
      _isLoading = true;
    });

    final patientName = _isMinor
        ? _minorNameController.text.trim()
        : _nombreController.text.trim();
    final patientDni =
        _isMinor ? _minorDniController.text.trim() : _dniController.text.trim();

    final signaturePayload = <String, dynamic>{
      'userId': widget.userId,
      'documentId': widget.documentId,
      'code': codigo,
      'signerData': <String, String>{
        'fullName': _nombreController.text.trim(),
        'dni': _dniController.text.trim(),
        'address': _direccionController.text.trim(),
        'cp': _cpController.text.trim(),
        'city': _localidadController.text.trim(),
      },
      'patientData': <String, Object>{
        'isMinor': _isMinor,
        'fullName': patientName,
        'dni': patientDni.isEmpty ? 'N/A' : patientDni,
      },
      'consents': _consentSelections,
      'metadata': <String, String>{
        'devicePlatform': Theme.of(context).platform.toString(),
        'localTimestamp': DateTime.now().toIso8601String(),
      },
    };

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await http.post(
        Uri.parse(_verificarOtpUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(signaturePayload),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Firma completada correctamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
        });
        // CORRECCIÓN: Casting explícito
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception((data['error'] as String?) ?? 'Código incorrecto');
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _abrirDocumento() async {
    if (_pdfUrl == null || _pdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró la URL del documento'),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(_pdfUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          _haAbiertoDocumento = true;
        });
      } else {
        throw Exception('No se pudo lanzar la URL');
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el PDF: $e')),
        );
      }
    }
  }

  void _mostrarDialogoOTP() {
    _otpController.clear();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Firma Digital OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Introduce el código de 6 dígitos enviado a tu correo:',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 5,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _validarFirma,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('FIRMAR AHORA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rellenar y Firmar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'DOCUMENTO A FIRMAR:',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.documentTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _abrirDocumento,
                        icon: Icon(
                          _haAbiertoDocumento
                              ? Icons.check_circle
                              : Icons.remove_red_eye,
                        ),
                        label: Text(
                          _haAbiertoDocumento
                              ? 'DOCUMENTO LEÍDO'
                              : 'LEER DOCUMENTO COMPLETO',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _haAbiertoDocumento
                              ? Colors.green.shade600
                              : Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 40),
                    const Text(
                      '1. DATOS DEL FIRMANTE (TUTOR/ADULTO)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF9F9F9),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _dniController,
                      decoration: const InputDecoration(
                        labelText: 'DNI / NIE / Pasaporte *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección Completa *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'C.P. *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (String? v) =>
                                v!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _localidadController,
                            decoration: const InputDecoration(
                              labelText: 'Localidad *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (String? v) =>
                                v!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: <Widget>[
                          SwitchListTile(
                            title: const Text(
                              '¿El paciente es MENOR de edad?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Activa esto si firmas como tutor legal',
                            ),
                            value: _isMinor,
                            onChanged: (bool v) => setState(() => _isMinor = v),
                          ),
                          if (_isMinor)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                15,
                                0,
                                15,
                                20,
                              ),
                              child: Column(
                                children: <Widget>[
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _minorNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre del Menor *',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (String? v) =>
                                        (_isMinor && (v == null || v.isEmpty))
                                            ? 'Requerido'
                                            : null,
                                  ),
                                  const SizedBox(height: 15),
                                  TextFormField(
                                    controller: _minorDniController,
                                    decoration: const InputDecoration(
                                      labelText: 'DNI del Menor (Opcional)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (widget.consentOptions.isNotEmpty) ...<Widget>[
                      const Text(
                        '3. CONSENTIMIENTOS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ...widget.consentOptions.map(
                        (String opt) => CheckboxListTile(
                          title: Text(opt),
                          value: _consentSelections[opt],
                          onChanged: (bool? v) => setState(
                            () => _consentSelections[opt] = v!,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Divider(thickness: 2),
                    Opacity(
                      opacity: _haAbiertoDocumento ? 1.0 : 0.5,
                      child: CheckboxListTile(
                        title: const Text(
                          'He leído el documento y acepto las condiciones.',
                        ),
                        value: _aceptadoCondiciones,
                        activeColor: Colors.green,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? v) {
                          if (!_haAbiertoDocumento) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lee el documento primero.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _aceptadoCondiciones = v!);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_aceptadoCondiciones && !_isSendingEmail)
                            ? _solicitarCodigo
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSendingEmail
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'SOLICITAR CÓDIGO DE FIRMA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
