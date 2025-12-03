import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUploadExcelScreen extends StatefulWidget {
  const AdminUploadExcelScreen({super.key});

  @override
  State<AdminUploadExcelScreen> createState() => _AdminUploadExcelScreenState();
}

class _AdminUploadExcelScreenState extends State<AdminUploadExcelScreen> {
  // Estado para controlar qué tipo de importación estamos haciendo
  // 'pacientes' o 'citas'
  String _tipoImportacion = 'pacientes'; 
  File? _archivoSeleccionado;
  bool _isLoading = false;

  // Instrucciones dinámicas según el tipo
  String get _instrucciones {
    if (_tipoImportacion == 'pacientes') {
      return 'El Excel debe tener las columnas:\nNombre, Email, Telefono, Rol';
    } else {
      return 'El Excel debe tener las columnas:\nFecha (DD/MM/AAAA), Hora (HH:MM), Email Paciente, Tipo Clase';
    }
  }

  Future<void> _seleccionarArchivo() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'], // Solo permitimos Excel
    );

    if (result != null) {
      setState(() {
        _archivoSeleccionado = File(result.files.single.path!);
      });
    }
  }

  Future<void> _procesarSubida() async {
    if (_archivoSeleccionado == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Definir la ruta en Storage según el tipo
      final String carpeta = _tipoImportacion == 'pacientes' ? 'imports_pacientes' : 'imports_citas';
      final String fileName = '${_tipoImportacion}_${DateTime.now().millisecondsSinceEpoch}.${_archivoSeleccionado!.path.split('.').last}';
      
      // 2. Subir el archivo
      final Reference ref = FirebaseStorage.instance.ref().child('$carpeta/$fileName');
      await ref.putFile(_archivoSeleccionado!);
      final String downloadUrl = await ref.getDownloadURL();

      // 3. Crear registro en Firestore para que una Cloud Function lo procese
      // NOTA: Normalmente aquí se activa una Cloud Function. Creamos un registro de "solicitud".
      await FirebaseFirestore.instance.collection('import_requests').add({
        'tipo': _tipoImportacion, // 'pacientes' o 'citas'
        'urlArchivo': downloadUrl,
        'estado': 'pendiente', // La Cloud Function cambiaría esto a 'procesando' -> 'completado'
        'creadoEn': FieldValue.serverTimestamp(),
        'nombreArchivoOriginal': fileName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo de $_tipoImportacion subido. El servidor lo procesará en breve.'),
            backgroundColor: Colors.green,
          )
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importación Masiva'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN 1: SELECTOR DE TIPO
            const Text('¿Qué datos vas a importar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildSelectorCard(
                    label: 'PACIENTES', 
                    icon: Icons.group_add, 
                    value: 'pacientes',
                    color: Colors.blue
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSelectorCard(
                    label: 'CITAS', 
                    icon: Icons.calendar_month, 
                    value: 'citas',
                    color: Colors.orange
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // SECCIÓN 2: INSTRUCCIONES
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade700),
                      const SizedBox(width: 10),
                      Text('Formato Requerido ($_tipoImportacion)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_instrucciones, style: TextStyle(color: Colors.grey.shade800)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // SECCIÓN 3: SELECCIÓN DE ARCHIVO
            InkWell(
              onTap: _seleccionarArchivo,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _archivoSeleccionado != null ? Colors.purple.shade50 : Colors.white,
                  border: Border.all(
                    color: _archivoSeleccionado != null ? Colors.purple : Colors.grey.shade400,
                    width: 2,
                    style: _archivoSeleccionado != null ? BorderStyle.solid : BorderStyle.solid
                  ),
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _archivoSeleccionado != null ? Icons.description : Icons.upload_file, 
                      size: 50, 
                      color: _archivoSeleccionado != null ? Colors.purple : Colors.grey
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _archivoSeleccionado != null 
                        ? _archivoSeleccionado!.path.split('/').last 
                        : 'Toca para buscar Excel (.xlsx, .csv)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: _archivoSeleccionado != null ? Colors.purple : Colors.grey
                      )
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // BOTÓN DE ACCIÓN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading || _archivoSeleccionado == null ? null : _procesarSubida,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('IMPORTAR ${_tipoImportacion.toUpperCase()}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las tarjetas de selección
  Widget _buildSelectorCard({required String label, required IconData icon, required String value, required Color color}) {
    final bool isSelected = _tipoImportacion == value;
    return GestureDetector(
      onTap: () => setState(() { 
        _tipoImportacion = value; 
        _archivoSeleccionado = null; // Reseteamos archivo al cambiar de modo
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 30),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isSelected ? color : Colors.grey
            )),
          ],
        ),
      ),
    );
  }
}