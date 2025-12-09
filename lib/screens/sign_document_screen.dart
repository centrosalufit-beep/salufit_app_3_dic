import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // NECESARIO PARA EL TOKEN
import 'package:url_launcher/url_launcher.dart'; // NECESARIO PARA ABRIR PDF

class SignDocumentScreen extends StatefulWidget {
  final String userId;
  final String documentId;
  final String documentTitle;
  final List<String> consentOptions; 

  const SignDocumentScreen({
    super.key,
    required this.userId,
    required this.documentId,
    required this.documentTitle,
    this.consentOptions = const [], 
  });

  @override
  State<SignDocumentScreen> createState() => _SignDocumentScreenState();
}

class _SignDocumentScreenState extends State<SignDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLADORES ---
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _cpController = TextEditingController();
  final TextEditingController _localidadController = TextEditingController();
  
  final TextEditingController _minorNameController = TextEditingController();
  final TextEditingController _minorDniController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // --- ESTADO ---
  bool _isLoading = true;
  bool _isSendingEmail = false;
  bool _aceptadoCondiciones = false;
  bool _haAbiertoDocumento = false;
  bool _isMinor = false;
  String? _pdfUrl; // Variable para guardar la URL real del PDF
  
  final Map<String, bool> _consentSelections = {};

  // URLS CLOUD FUNCTIONS
  final String _enviarOtpUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/enviarCodigoOTP';
  final String _verificarOtpUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/verificarCodigoOTP';

  @override
  void initState() {
    super.initState();
    _initConsentMap();
    _cargarDatosIniciales();
  }

  void _initConsentMap() {
    for (var option in widget.consentOptions) {
      _consentSelections[option] = false;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      // 1. Cargar datos del Usuario
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        _nombreController.text = data['nombreCompleto'] ?? '';
        _dniController.text = data['dni'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        _cpController.text = data['cp'] ?? '';
        _localidadController.text = data['localidad'] ?? '';
      }

      // 2. Cargar URL del documento (para poder abrirlo)
      final docSnapshot = await FirebaseFirestore.instance.collection('documents').doc(widget.documentId).get();
      if (docSnapshot.exists) {
        final docData = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _pdfUrl = docData['urlPdf']; // Guardamos la URL
        });
      }

    } catch (e) {
      debugPrint('Error cargando datos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNCIÓN PARA OBTENER EL TOKEN SEGURO ---
  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // 1. SOLICITUD DE OTP (CORREGIDA)
  Future<void> _solicitarCodigo() async {
    if (!_formKey.currentState!.validate()) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa los campos obligatorios en rojo')));
       return;
    }
    
    if (!_haAbiertoDocumento) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('POR FAVOR: Abre y lee el documento PDF antes de firmar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_aceptadoCondiciones) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar las condiciones')),
      );
      return;
    }

    setState(() { _isSendingEmail = true; });

    try {
      // OBTENER TOKEN
      final token = await _getAuthToken();
      if (token == null) throw Exception('Usuario no autenticado');

      final response = await http.post(
        Uri.parse(_enviarOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // <--- AQUÍ ESTÁ LA SOLUCIÓN AL ERROR ROJO
        },
        body: jsonEncode({
          'userId': widget.userId,
          'documentId': widget.documentId,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código de seguridad enviado a tu email'), backgroundColor: Colors.green),
        );
        _mostrarDialogoOTP();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Error desconocido del servidor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isSendingEmail = false; });
    }
  }

  // 2. VERIFICACIÓN FIRMA (CORREGIDA)
  Future<void> _validarFirma() async {
    final String codigo = _otpController.text.trim();
    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código debe tener 6 dígitos')));
      return;
    }

    Navigator.pop(context); 
    setState(() { _isLoading = true; });

    final String patientName = _isMinor ? _minorNameController.text.trim() : _nombreController.text.trim();
    final String patientDni = _isMinor ? _minorDniController.text.trim() : _dniController.text.trim();

    final Map<String, dynamic> signaturePayload = {
      'userId': widget.userId,
      'documentId': widget.documentId,
      'code': codigo,
      'signerData': {
        'fullName': _nombreController.text.trim(),
        'dni': _dniController.text.trim(),
        'address': _direccionController.text.trim(),
        'cp': _cpController.text.trim(),
        'city': _localidadController.text.trim(),
      },
      'patientData': {
        'isMinor': _isMinor,
        'fullName': patientName,
        'dni': patientDni.isEmpty ? 'N/A' : patientDni,
      },
      'consents': _consentSelections,
      'metadata': {
        'devicePlatform': Theme.of(context).platform.toString(),
        'localTimestamp': DateTime.now().toIso8601String(),
      }
    };

    try {
      // OBTENER TOKEN TAMBIÉN AQUÍ
      final token = await _getAuthToken();
      if (token == null) throw Exception('Usuario no autenticado');

      final response = await http.post(
        Uri.parse(_verificarOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // <--- HEADER DE SEGURIDAD
        },
        body: jsonEncode(signaturePayload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Firma completada correctamente!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      } else {
        setState(() { _isLoading = false; });
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Código incorrecto');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- FUNCIÓN PARA ABRIR EL PDF REAL ---
  Future<void> _abrirDocumento() async {
    if (_pdfUrl == null || _pdfUrl!.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Error: No se encontró la URL del documento')),
       );
       return;
    }

    try {
      final Uri uri = Uri.parse(_pdfUrl!);
      // Usamos externalApplication para que lo abra el visor de PDF del móvil (Drive, Chrome, etc)
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() { _haAbiertoDocumento = true; });
      } else {
        throw 'No se pudo lanzar la URL';
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el PDF: $e')),
      );
    }
  }

  void _mostrarDialogoOTP() {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Firma Digital OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Introduce el código de 6 dígitos enviado a tu correo:'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: '000000', border: OutlineInputBorder(), counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: _validarFirma, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('FIRMAR AHORA')),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DOCUMENTO A FIRMAR:', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(widget.documentTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _abrirDocumento,
                        icon: Icon(_haAbiertoDocumento ? Icons.check_circle : Icons.remove_red_eye),
                        label: Text(_haAbiertoDocumento ? 'DOCUMENTO LEÍDO' : 'LEER DOCUMENTO COMPLETO'),
                        style: ElevatedButton.styleFrom(backgroundColor: _haAbiertoDocumento ? Colors.green.shade600 : Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                    ),
                    const Divider(height: 40),
                    const Text('1. DATOS DEL FIRMANTE (TUTOR/ADULTO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFFF9F9F9)), readOnly: true),
                    const SizedBox(height: 15),
                    TextFormField(controller: _dniController, decoration: const InputDecoration(labelText: 'DNI / NIE / Pasaporte *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                    const SizedBox(height: 15),
                    TextFormField(controller: _direccionController, decoration: const InputDecoration(labelText: 'Dirección Completa *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(flex: 2, child: TextFormField(controller: _cpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'C.P. *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                        const SizedBox(width: 15),
                        Expanded(flex: 3, child: TextFormField(controller: _localidadController, decoration: const InputDecoration(labelText: 'Localidad *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          SwitchListTile(title: const Text('¿El paciente es MENOR de edad?', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Activa esto si firmas como tutor legal'), value: _isMinor, onChanged: (v) => setState(() => _isMinor = v)),
                          if (_isMinor) Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                            child: Column(children: [const Divider(), const SizedBox(height: 10), TextFormField(controller: _minorNameController, decoration: const InputDecoration(labelText: 'Nombre del Menor *', border: OutlineInputBorder()), validator: (v) => (_isMinor && (v == null || v.isEmpty)) ? 'Requerido' : null), const SizedBox(height: 15), TextFormField(controller: _minorDniController, decoration: const InputDecoration(labelText: 'DNI del Menor (Opcional)', border: OutlineInputBorder()))]),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (widget.consentOptions.isNotEmpty) ...[
                      const Text('3. CONSENTIMIENTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ...widget.consentOptions.map((opt) => CheckboxListTile(title: Text(opt), value: _consentSelections[opt], onChanged: (v) => setState(() => _consentSelections[opt] = v!))),
                      const SizedBox(height: 20),
                    ],
                    const Divider(thickness: 2),
                    Opacity(
                      opacity: _haAbiertoDocumento ? 1.0 : 0.5,
                      child: CheckboxListTile(title: const Text('He leído el documento y acepto las condiciones.'), value: _aceptadoCondiciones, activeColor: Colors.green, controlAffinity: ListTileControlAffinity.leading, onChanged: (v) {
                        if (!_haAbiertoDocumento) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lee el documento primero.'))); return; }
                        setState(() => _aceptadoCondiciones = v!);
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: (_aceptadoCondiciones && !_isSendingEmail) ? _solicitarCodigo : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white), child: _isSendingEmail ? const CircularProgressIndicator(color: Colors.white) : const Text('SOLICITAR CÓDIGO DE FIRMA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}