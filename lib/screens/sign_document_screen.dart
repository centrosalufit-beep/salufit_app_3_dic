import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class SignDocumentScreen extends StatefulWidget {
  final String userId;
  final String documentId;
  final String documentTitle;

  const SignDocumentScreen({
    super.key,
    required this.userId,
    required this.documentId,
    required this.documentTitle,
  });

  @override
  State<SignDocumentScreen> createState() => _SignDocumentScreenState();
}

class _SignDocumentScreenState extends State<SignDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _cpController = TextEditingController();
  final TextEditingController _localidadController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = true;
  bool _isSendingEmail = false;
  bool _aceptado = false;
  bool _haAbiertoDocumento = false;

  // URLS DE TUS FUNCIONES
  final String _enviarOtpUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/enviarCodigoOTP';
  final String _verificarOtpUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/verificarCodigoOTP';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        _nombreController.text = data['nombreCompleto'] ?? '';
        _dniController.text = data['dni'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        _cpController.text = data['cp'] ?? '';
        _localidadController.text = data['localidad'] ?? '';
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _solicitarCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_haAbiertoDocumento) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes abrir y leer el documento antes de firmar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_aceptado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes marcar la casilla de aceptación')),
      );
      return;
    }

    setState(() { _isSendingEmail = true; });

    try {
      final response = await http.post(
        Uri.parse(_enviarOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'documentId': widget.documentId,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código enviado a tu email'), backgroundColor: Colors.green),
        );
        _mostrarDialogoOTP();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Error al enviar email'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isSendingEmail = false; });
    }
  }

  Future<void> _validarFirma() async {
    final String codigo = _otpController.text.trim();
    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código debe tener 6 dígitos')));
      return;
    }

    final String dni = _dniController.text.trim();
    final String direccion = _direccionController.text.trim();
    final String cp = _cpController.text.trim();
    final String localidad = _localidadController.text.trim();

    Navigator.pop(context); 
    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse(_verificarOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'documentId': widget.documentId,
          'code': codigo,
          'dni': dni,
          'direccion': direccion,
          'cp': cp,
          'localidad': localidad,
        }),
      );

      final data = jsonDecode(response.body);

      // CORRECCIÓN: Verificar mounted antes de usar context tras el await
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Documento firmado y registrado!'), backgroundColor: Colors.green),
        );
        if (mounted) Navigator.pop(context); 
      } else {
        setState(() { _isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Error al verificar'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoOTP() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Valida tu Firma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Introduce el código de 6 dígitos que hemos enviado a tu email:'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _validarFirma,
            child: const Text('FIRMAR DOCUMENTO'),
          ),
        ],
      ),
    );
  }

  void _abrirDocumento() {
    setState(() { _haAbiertoDocumento = true; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo documento PDF...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos del Firmante')),
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
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vas a firmar:', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(widget.documentTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _abrirDocumento,
                        icon: Icon(_haAbiertoDocumento ? Icons.check : Icons.remove_red_eye),
                        label: Text(_haAbiertoDocumento ? 'Documento Leído' : 'LEER DOCUMENTO COMPLETO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _haAbiertoDocumento ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    if (!_haAbiertoDocumento)
                       const Padding(
                         padding: EdgeInsets.only(top: 8.0),
                         child: Center(child: Text('* Debes abrir el documento para poder continuar', style: TextStyle(color: Colors.red, fontSize: 12))),
                       ),

                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFFF0F0F0)),
                      readOnly: true,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _dniController,
                      decoration: const InputDecoration(labelText: 'DNI / NIE / Pasaporte *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                      validator: (value) => value!.isEmpty ? 'El DNI es obligatorio' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(labelText: 'Dirección (Calle y número) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                      validator: (value) => value!.isEmpty ? 'La dirección es obligatoria' : null,
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'C.P. * (en números)', border: OutlineInputBorder()),
                            validator: (value) => value!.isEmpty ? 'Falta CP' : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _localidadController,
                            decoration: const InputDecoration(labelText: 'Localidad *', border: OutlineInputBorder()),
                            validator: (value) => value!.isEmpty ? 'Falta localidad' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Opacity(
                      opacity: _haAbiertoDocumento ? 1.0 : 0.5,
                      child: CheckboxListTile(
                        title: const Text('He leído el documento y acepto las condiciones.'),
                        value: _aceptado,
                        onChanged: (val) {
                          if (!_haAbiertoDocumento) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor, pulsa el botón azul para LEER el documento primero.')),
                            );
                            return;
                          }
                          setState(() => _aceptado = val!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_aceptado && !_isSendingEmail) ? _solicitarCodigo : null, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSendingEmail
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SOLICITAR CÓDIGO DE FIRMA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Center(
                      child: TextButton(
                        onPressed: () {
                            if (!_aceptado) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Debes marcar la casilla de aceptación primero')),
                              );
                              return;
                            }
                            _mostrarDialogoOTP();
                        },
                        child: const Text('Ya tengo un código, quiero introducirlo', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}