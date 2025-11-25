import 'dart:io';
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return;

      setState(() {
        _isLoading = true;
        _status = 'Leyendo archivo y base de datos...';
        _progress = 0.1;
      });

      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      _status = 'Descargando lista de pacientes...';
      var usersSnap = await FirebaseFirestore.instance.collection('users').get();
      
      Map<String, String> userMap = {};
      for (var doc in usersSnap.docs) {
        String nombre = (doc.data()['nombreCompleto'] ?? '').toString().toLowerCase().trim();
        if (nombre.isNotEmpty) {
          userMap[nombre] = doc.id;
        }
      }

      String sheetName = excel.tables.keys.firstWhere(
        (k) => k.toUpperCase() == 'CITAS',
        orElse: () => excel.tables.keys.first
      );

      var table = excel.tables[sheetName];
      if (table == null) throw 'No se encontró la pestaña CITAS';

      int totalRows = table.maxRows;
      int errors = 0;
      int success = 0;

      var batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;

      for (int i = 1; i < totalRows; i++) {
        var row = table.rows[i];
        if (row.isEmpty) continue;

        try {
          var pacienteNombre = _getCellValue(row[2]); 
          var fechaStr = _getCellValue(row[3]);       
          var horaInicioStr = _getCellValue(row[4]);  
          var especialidad = _getCellValue(row[10]);  
          var profesional = _getCellValue(row[1]);    

          if (pacienteNombre.isEmpty || fechaStr.isEmpty) continue;

          String? userId = userMap[pacienteNombre.toLowerCase().trim()];
          
          if (userId != null) {
            DateTime fechaBase = DateFormat('dd/MM/yyyy').parse(fechaStr);
            TimeOfDay hora = _parseTime(horaInicioStr);
            
            DateTime fechaFinal = DateTime(fechaBase.year, fechaBase.month, fechaBase.day, hora.hour, hora.minute);

            var docRef = FirebaseFirestore.instance.collection('appointments').doc(); 
            
            batch.set(docRef, {
              'userId': userId,
              'pacienteNombre': pacienteNombre,
              'profesional': profesional,
              'especialidad': especialidad,
              'fechaHoraInicio': Timestamp.fromDate(fechaFinal),
              'estado': 'Pendiente',
              'origen': 'Importación App'
            });

            batchCount++;
            success++;
          } else {
            print('No encontrado usuario: $pacienteNombre');
            errors++;
          }

        } catch (e) {
          print('Error en fila $i: $e');
          errors++;
        }

        if (batchCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCount = 0;
        }

        setState(() {
          _progress = i / totalRows;
          _status = 'Procesando... ($success OK / $errors Errores)';
        });
      }

      if (batchCount > 0) await batch.commit();

      setState(() {
        _isLoading = false;
        _status = 'Finalizado: $success citas importadas. $errors usuarios no encontrados.';
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

  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      List<String> parts = timeStr.split(':');
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
            const Text('Asegúrate de que la pestaña se llame CITAS y tenga el formato estándar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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