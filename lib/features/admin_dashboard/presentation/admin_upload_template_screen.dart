import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart'; // NECESARIO PARA PREVISUALIZACIÓN

class AdminUploadTemplateScreen extends StatefulWidget {
  const AdminUploadTemplateScreen({super.key});

  @override
  State<AdminUploadTemplateScreen> createState() =>
      _AdminUploadTemplateScreenState();
}

class _AdminUploadTemplateScreenState extends State<AdminUploadTemplateScreen> {
  final TextEditingController _tituloController = TextEditingController();
  File? _pdfSeleccionado;
  Uint8List? _pdfBytes; // Para la previsualización
  bool _isLoading = false;

  Future<void> _seleccionarPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Leemos los bytes para la previsualización (compatible con Web/Móvil)
        Uint8List? bytes;
        if (file.bytes != null) {
          bytes = file.bytes;
        } else if (file.path != null) {
          final f = File(file.path!);
          bytes = await f.readAsBytes();
        }

        if (mounted) {
          setState(() {
            if (file.path != null) _pdfSeleccionado = File(file.path!);
            _pdfBytes = bytes;
          });
        }
      }
    } on Exception catch (e) {
      debugPrint('Error seleccionando PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al leer el archivo')),
        );
      }
    }
  }

  Future<void> _subirPlantilla() async {
    if (_pdfSeleccionado == null || _tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta título o archivo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileName = 'templates/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      // Subida robusta
      await ref.putFile(_pdfSeleccionado!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('consent_templates')
          .add(<String, dynamic>{
        'titulo': _tituloController.text.trim(),
        'urlPdf': url,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'activo': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plantilla subida y activa'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Plantilla Legal'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // FORMULARIO SUPERIOR
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Sube un consentimiento vacío (PDF) para uso legal.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título del Documento',
                      hintText: 'Ej: Consentimiento RGPD',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                ],
              ),
            ),

            // ZONA DE PREVISUALIZACIÓN O SELECCIÓN
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _pdfBytes == null
                    ? InkWell(
                        onTap: _seleccionarPdf,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.upload_file,
                                size: 50,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Toca para seleccionar PDF',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(10),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Row(
                                  children: <Widget>[
                                    Icon(Icons.visibility, color: Colors.teal),
                                    SizedBox(width: 8),
                                    Text(
                                      'Previsualización',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: _seleccionarPdf,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Cambiar'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: PdfPreview(
                              build: (PdfPageFormat format) => _pdfBytes!,
                              useActions: false, // Desactiva imprimir/compartir
                              scrollViewDecoration: const BoxDecoration(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // BOTÓN DE ACCIÓN
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _subirPlantilla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: const Text(
                  'CONFIRMAR Y SUBIR PLANTILLA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
