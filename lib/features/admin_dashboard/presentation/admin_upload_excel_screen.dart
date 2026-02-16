import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AdminUploadExcelScreen extends StatefulWidget {
  const AdminUploadExcelScreen({super.key});

  @override
  State<AdminUploadExcelScreen> createState() => _AdminUploadExcelScreenState();
}

class _AdminUploadExcelScreenState extends State<AdminUploadExcelScreen> {
  String _tipoImportacion = 'pacientes'; // 'pacientes' o 'citas'
  File? _archivoSeleccionado;
  bool _isLoading = false;
  String _status = 'Selecciona archivo .xlsx';

  // --- LIMPIEZA DE TEXTO (Vital para el matching de nombres) ---
  String removeDiacritics(String str) {
    if (str.isEmpty) return '';
    var result = str;
    const withDia =
        'Ãƒâ‚¬ÃƒÂÃƒâ€šÃƒÆ’Ãƒâ€žÃƒâ€¦ÃƒÂ ÃƒÂ¡ÃƒÂ¢ÃƒÂ£ÃƒÂ¤ÃƒÂ¥Ãƒâ€™Ãƒâ€œÃƒâ€Ãƒâ€¢Ãƒâ€¢Ãƒâ€“ÃƒËœÃƒÂ²ÃƒÂ³ÃƒÂ´ÃƒÂµÃƒÂ¶ÃƒÂ¸ÃƒË†Ãƒâ€°ÃƒÅ Ãƒâ€¹ÃƒÂ¨ÃƒÂ©ÃƒÂªÃƒÂ«ÃƒÂ°Ãƒâ€¡ÃƒÂ§ÃƒÂÃƒÅ’ÃƒÂÃƒÅ½ÃƒÂÃƒÂ¬ÃƒÂ­ÃƒÂ®ÃƒÂ¯Ãƒâ„¢ÃƒÅ¡Ãƒâ€ºÃƒÅ“ÃƒÂ¹ÃƒÂºÃƒÂ»ÃƒÂ¼Ãƒâ€˜ÃƒÂ±Ã…Â Ã…Â¡Ã…Â¸ÃƒÂ¿ÃƒÂ½Ã…Â½Ã…Â¾';
    const withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (var i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    // Convertimos a minÃƒÂºsculas y normalizamos espacios
    return result.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _formatId(dynamic value) {
    if (value == null) return '';
    final id = value.toString().split('.').first;
    return id.trim().padLeft(6, '0');
  }

  // Helper seguro para celdas de Excel
  String _safeCell(Data? cell) {
    if (cell == null || cell.value == null) return '';

    final val = cell.value;

    // --- CORRECCIÃƒâ€œN AQUÃƒÂ ---
    // TextCellValue devuelve un objeto TextSpan, no un String directo.
    if (val is TextCellValue) {
      return val.value.text?.trim() ?? '';
    }

    // Para otros tipos (Int, Double, Date), toString suele funcionar bien
    return val.toString().trim();
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && mounted) {
      setState(() {
        _archivoSeleccionado = File(result.files.single.path!);
        _status = 'Archivo cargado: ${result.files.single.name}';
      });
    }
  }

  Future<void> _ejecutarImportacion() async {
    if (_archivoSeleccionado == null) return;
    setState(() {
      _isLoading = true;
      _status = 'Leyendo datos...';
    });

    try {
      final bytes = _archivoSeleccionado!.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('El archivo Excel estÃƒÂ¡ vacÃƒÂ­o o daÃƒÂ±ado');
      }

      // Tomamos la primera hoja disponible
      final sheet = excel.tables.values.first;
      final totalRows = sheet.maxRows;

      if (_tipoImportacion == 'pacientes') {
        await _importarPacientes(sheet, totalRows);
      } else {
        await _importarCitas(sheet, totalRows);
      }
    } on Exception catch (e) {
      debugPrint('Error ImportaciÃƒÂ³n: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Error: $e';
        });
      }
    }
  }

  // --- IMPORTACIÃƒâ€œN DE PACIENTES (Legacy) ---
  Future<void> _importarPacientes(Sheet sheet, int totalRows) async {
    var procesados = 0;
    var batch = FirebaseFirestore.instance.batch();
    var batchCount = 0;

    for (var i = 1; i < totalRows; i++) {
      final row = sheet.rows[i];
      if (row.length < 4) continue;

      final rawId = _formatId(row[0]?.value);
      if (rawId.isEmpty || rawId == '000000') continue;

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(rawId),
        <String, Object>{
          'id': rawId,
          'nombreCompleto': '${_safeCell(row[1])} ${_safeCell(row[2])}'.trim(),
          'nombre': _safeCell(row[1]),
          'apellidos': _safeCell(row[2]),
          'email': _safeCell(row[3]).toLowerCase(),
          'rol': 'cliente',
          'activo': true,
          'actualizadoEn': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batchCount++;
      procesados++;
      if (batchCount >= 100) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) await batch.commit();
    _finalizar(procesados);
  }

  // --- IMPORTACIÃƒâ€œN DE CITAS (Columnas B, C, D, E, J) ---
  Future<void> _importarCitas(Sheet sheet, int totalRows) async {
    setState(() => _status = 'Indexando pacientes...');

    // 1. CARGA DE DICCIONARIO DE PACIENTES
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('activado', isEqualTo: true)
        .get();
    final nameToId = <String, String>{};

    print('--- DICCIONARIO DE USUARIOS ---');
    for (final doc in userSnap.docs) {
      final data = doc.data();
      final full = (data['nombreCompleto'] ?? '').toString();
      final key = removeDiacritics(full);

      if (key.isNotEmpty) {
        nameToId[key] = doc.id;
        if (full.isEmpty) {
          final n = (data['nombre'] ?? '').toString();
          final a = (data['apellidos'] ?? '').toString();
          final reconstructed = removeDiacritics('$n $a');
          if (reconstructed.isNotEmpty) nameToId[reconstructed] = doc.id;
        }
      }
    }
    print('Total usuarios indexados: ${nameToId.length}');
    print('---------------------------------------');

    var procesados = 0;
    var ignorados = 0;
    var batch = FirebaseFirestore.instance.batch();
    var batchCount = 0;

    for (var i = 1; i < totalRows; i++) {
      final row = sheet.rows[i];
      if (row.length < 5) continue;

      // --- LECTURA DE COLUMNAS ---
      // Col B [1]: Profesional
      final profesional = _safeCell(row[1]);

      // Col C [2]: Paciente (Clave de Match)
      final pacienteRaw = _safeCell(row[2]);
      final pacienteKey = removeDiacritics(pacienteRaw);

      // Col D [3]: Fecha (CellValue)
      final fechaVal = row[3]?.value;

      // Col E [4]: Hora Inicio (CellValue)
      final horaVal = row[4]?.value;

      // Col J [9]: FacturaciÃƒÂ³n (Opcional)
      final precioRaw = row.length > 9 ? _safeCell(row[9]) : '0';

      // 2. BUSCAR USUARIO (MATCH)
      final userId = nameToId[pacienteKey];

      if (userId == null) {
        print(
          'Ã¢Å¡Â Ã¯Â¸Â OMITIDO Fila ${i + 1}: No encuentro a "$pacienteRaw" (Clave: "$pacienteKey")',
        );
        ignorados++;
        continue;
      }

      // 3. PARSEO DE FECHA Y HORA ROBUSTO
      try {
        DateTime fechaBase;

        // A. Parseo Fecha
        if (fechaVal is DateCellValue) {
          fechaBase = DateTime(fechaVal.year, fechaVal.month, fechaVal.day);
        } else if (fechaVal is DateTimeCellValue) {
          fechaBase = DateTime(fechaVal.year, fechaVal.month, fechaVal.day);
        } else {
          // Fallback a String: "31/12/2025" o "2025-12-31"
          final fStr = fechaVal.toString().trim();
          if (fStr.contains('/')) {
            final parts = fStr.split('/');
            fechaBase = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          } else {
            fechaBase = DateTime.parse(fStr);
          }
        }

        // B. Parseo Hora
        var hora = 0;
        var minuto = 0;

        if (horaVal is TimeCellValue) {
          hora = horaVal.hour;
          minuto = horaVal.minute;
        } else if (horaVal is DateTimeCellValue) {
          hora = horaVal.hour;
          minuto = horaVal.minute;
        } else {
          // Fallback a String: "10:30"
          final hStr = horaVal.toString().trim();
          if (hStr.contains(':')) {
            final parts = hStr.split(':');
            hora = int.parse(parts[0]);
            minuto = int.parse(parts[1]);
          }
        }

        // C. CombinaciÃƒÂ³n
        final inicio = DateTime(
          fechaBase.year,
          fechaBase.month,
          fechaBase.day,
          hora,
          minuto,
        );

        // 4. PREPARAR ESCRITURA
        final citaId = '${userId}_${inicio.millisecondsSinceEpoch}';

        batch.set(
          FirebaseFirestore.instance.collection('appointments').doc(citaId),
          {
            'userId': userId,
            'pacienteNombreCompleto': pacienteRaw,
            'profesionalId': profesional,
            'fechaHoraInicio': Timestamp.fromDate(inicio),
            'especialidad': 'Consulta Importada',
            'estado': 'confirmada',
            'precioEstimado':
                double.tryParse(precioRaw.replaceAll(',', '.')) ?? 0.0,
            'importadoEl': FieldValue.serverTimestamp(),
            'origen': 'excel_admin',
          },
          SetOptions(merge: true),
        );

        print('Ã¢Å“â€¦ MATCH Fila ${i + 1}: $pacienteRaw -> $inicio');

        batchCount++;
        procesados++;

        if (batchCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCount = 0;
          if (mounted) setState(() => _status = 'Subiendo... $procesados');
        }
      } on Exception catch (e) {
        print(
          'Ã¢ÂÅ’ ERROR Fila ${i + 1} ($pacienteRaw): Error fecha. D: "$fechaVal", E: "$horaVal". Error: $e',
        );
        ignorados++;
      }
    }

    if (batchCount > 0) await batch.commit();
    _finalizar(procesados, warnings: ignorados);
  }

  void _finalizar(int count, {int warnings = 0}) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _status = 'Finalizado: $count importados. ($warnings omitidos)';
    });
    final color = warnings > 0 ? Colors.orange : Colors.green;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Proceso terminado. $count ÃƒÂ©xitos, $warnings omitidos (ver consola).',
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importador Salufit (Excel)'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('1. SUBIR PACIENTES'),
                      selected: _tipoImportacion == 'pacientes',
                      onSelected: (v) =>
                          setState(() => _tipoImportacion = 'pacientes'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('2. SUBIR CITAS'),
                      selected: _tipoImportacion == 'citas',
                      onSelected: (v) =>
                          setState(() => _tipoImportacion = 'citas'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              InkWell(
                onTap: _isLoading ? null : _seleccionarArchivo,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _archivoSeleccionado != null
                          ? Colors.teal
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 40,
                        color: _archivoSeleccionado != null
                            ? Colors.teal
                            : Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _archivoSeleccionado != null
                            ? 'Listo: ${_archivoSeleccionado!.path.split(Platform.pathSeparator).last}'
                            : 'Haz clic para seleccionar Excel (.xlsx)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  _status,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _archivoSeleccionado == null
                        ? null
                        : _ejecutarImportacion,
                    child: Text('IMPORTAR ${_tipoImportacion.toUpperCase()}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
