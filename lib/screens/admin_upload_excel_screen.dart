import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminUploadExcelScreen extends StatefulWidget {
  const AdminUploadExcelScreen({super.key});

  @override
  State<AdminUploadExcelScreen> createState() => _AdminUploadExcelScreenState();
}

class _AdminUploadExcelScreenState extends State<AdminUploadExcelScreen> {
  bool _isLoading = false;
  String _status = 'Esperando archivo...';
  double _progress = 0.0;

  Future<void> _procesarExcel() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true, 
      );

      if (result == null) return;

      setState(() {
        _isLoading = true;
        _status = 'Leyendo archivo y base de datos...';
        _progress = 0.1;
      });

      List<int> bytes;
      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes!;
        } else {
          throw 'No se pudieron leer los datos del archivo (Web)';
        }
      } else {
        if (result.files.single.path != null) {
          final File file = File(result.files.single.path!);
          bytes = file.readAsBytesSync();
        } else {
          if (result.files.single.bytes != null) {
             bytes = result.files.single.bytes!;
          } else {
             throw 'No se encontró la ruta del archivo';
          }
        }
      }

      final excel = Excel.decodeBytes(bytes);

      setState(() { _status = 'Descargando lista de pacientes...'; });
      
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      
      final Map<String, String> userMap = {};
      final Map<String, String> userEmailMap = {}; 
      
      for (var doc in usersSnap.docs) {
        final data = doc.data();
        final String nombre = (data['nombreCompleto'] ?? '').toString().toLowerCase().trim();
        if (nombre.isNotEmpty) {
          userMap[nombre] = doc.id;
          if (data['email'] != null) {
            userEmailMap[doc.id] = data['email'];
          }
        }
      }

      final String sheetName = excel.tables.keys.firstWhere(
        (k) => k.toUpperCase() == 'CITAS',
        orElse: () => excel.tables.keys.first
      );

      final table = excel.tables[sheetName];
      if (table == null) throw 'No se encontró la pestaña CITAS';

      final int totalRows = table.maxRows;
      int errors = 0;
      int success = 0;
      // CORRECCIÓN: Eliminada variable 'duplicatesUpdated' no usada

      var batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;

      for (int i = 1; i < totalRows; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;

        try {
          final pacienteNombre = _getCellValue(row.length > 2 ? row[2] : null); 
          final fechaStr = _getCellValue(row.length > 3 ? row[3] : null);       
          final horaInicioStr = _getCellValue(row.length > 4 ? row[4] : null);  
          final especialidad = _getCellValue(row.length > 10 ? row[10] : null);  
          final profesional = _getCellValue(row.length > 1 ? row[1] : null);    

          if (pacienteNombre.isEmpty || fechaStr.isEmpty) continue;

          final String? userId = userMap[pacienteNombre.toLowerCase().trim()];
          
          if (userId != null) {
            DateTime fechaBase;
            try {
               fechaBase = DateFormat('dd/MM/yyyy').parse(fechaStr);
            } catch (e) {
               fechaBase = DateTime.parse(fechaStr);
            }

            final TimeOfDay hora = _parseTime(horaInicioStr);
            final DateTime fechaFinal = DateTime(fechaBase.year, fechaBase.month, fechaBase.day, hora.hour, hora.minute);

            final String uniqueDocId = '${userId}_${fechaFinal.millisecondsSinceEpoch}';
            
            final docRef = FirebaseFirestore.instance.collection('appointments').doc(uniqueDocId);
            final String? userEmail = userEmailMap[userId];

            batch.set(docRef, {
              'id': uniqueDocId, 
              'userId': userId,
              'userEmail': userEmail,
              'pacienteNombre': pacienteNombre,
              'profesional': profesional,
              'especialidad': especialidad,
              'fechaHoraInicio': Timestamp.fromDate(fechaFinal),
              'estado': 'Pendiente',
              'origen': 'Importación App'
            }, SetOptions(merge: true));

            batchCount++;
            success++;
          } else {
            debugPrint('No encontrado usuario: $pacienteNombre');
            errors++;
          }

        } catch (e) {
          debugPrint('Error en fila $i: $e');
          errors++;
        }

        if (batchCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCount = 0;
        }

        setState(() {
          _progress = i / totalRows;
          _status = 'Procesando... ($success procesados / $errors errores)';
        });
      }

      if (batchCount > 0) await batch.commit();

      setState(() {
        _isLoading = false;
        _status = 'Finalizado: $success citas procesadas (nuevas o actualizadas). $errors errores.';
        _progress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Importación completada'), backgroundColor: Colors.green));
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error crítico: $e';
      });
    }
  }

  String _getCellValue(dynamic cell) {
    if (cell == null) return '';
    if (cell.value == null) return '';
    return cell.value.toString().trim();
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final List<String> parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar Citas Excel')),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text('Sube el Excel de Citas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('El sistema detectará automáticamente si la cita ya existe para no duplicarla.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            
            if (_isLoading) ...[
              LinearProgressIndicator(value: _progress, color: Colors.green),
              const SizedBox(height: 10),
              Text(_status),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _procesarExcel,
                  icon: const Icon(Icons.file_open),
                  label: const Text('SELECCIONAR ARCHIVO'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              if (_status != 'Esperando archivo...')
                Text(_status, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ]
          ],
        ),
      ),
    );
  }
}