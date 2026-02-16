import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isRepairing = false;
  String _status = 'Listo para reparar';
  double _progress = 0;
  final List<String> _logs = <String>[];

  String removeDiacritics(String str) {
    // CORRECCIÃƒâ€œN: Variable local
    var result = str;
    const withDia =
        'Ãƒâ‚¬ÃƒÂÃƒâ€šÃƒÆ’Ãƒâ€žÃƒâ€¦ÃƒÂ ÃƒÂ¡ÃƒÂ¢ÃƒÂ£ÃƒÂ¤ÃƒÂ¥Ãƒâ€™Ãƒâ€œÃƒâ€Ãƒâ€¢Ãƒâ€¢Ãƒâ€“ÃƒËœÃƒÂ²ÃƒÂ³ÃƒÂ´ÃƒÂµÃƒÂ¶ÃƒÂ¸ÃƒË†Ãƒâ€°ÃƒÅ Ãƒâ€¹ÃƒÂ¨ÃƒÂ©ÃƒÂªÃƒÂ«ÃƒÂ°Ãƒâ€¡ÃƒÂ§ÃƒÂÃƒÅ’ÃƒÂÃƒÅ½ÃƒÂÃƒÂ¬ÃƒÂ­ÃƒÂ®ÃƒÂ¯Ãƒâ„¢ÃƒÅ¡Ãƒâ€ºÃƒÅ“ÃƒÂ¹ÃƒÂºÃƒÂ»ÃƒÂ¼Ãƒâ€˜ÃƒÂ±Ã…Â Ã…Â¡Ã…Â¸ÃƒÂ¿ÃƒÂ½Ã…Â½Ã…Â¾';
    const withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (var i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  List<String> _generateKeywords(String nombre, String id) {
    final keywords = <String>[];
    final nombreLimpio = removeDiacritics(nombre.toLowerCase().trim());
    final palabras = nombreLimpio.split(RegExp(r'\s+'));
    keywords.addAll(palabras);
    final idSinCeros = id.replaceFirst(RegExp('^0+'), '');
    keywords.add(id.toLowerCase());
    if (idSinCeros.isNotEmpty) keywords.add(idSinCeros);
    return keywords.toSet().toList();
  }

  Future<void> _ejecutarReparacion() async {
    setState(() {
      _isRepairing = true;
      _logs.clear();
      _status = 'Iniciando escaneo...';
      _progress = 0;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('activado', isEqualTo: true)
          .get();
      final total = snapshot.docs.length;
      var procesados = 0;

      var batch = FirebaseFirestore.instance.batch();
      var batchCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nombre =
            (data['nombreCompleto'] ?? data['nombre'] ?? '').toString();
        final id = doc.id;

        if (nombre.isEmpty) continue;

        final newKeywords = _generateKeywords(nombre, id);
        batch.update(doc.reference, <String, dynamic>{'keywords': newKeywords});

        _logs.add('Ã¢Å“â€¦ $nombre -> $newKeywords');
        batchCount++;
        procesados++;

        if (batchCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCount = 0;
        }

        setState(() {
          _progress = procesados / total;
          _status = 'Procesando $procesados de $total...';
        });
      }

      if (batchCount > 0) await batch.commit();

      setState(() {
        _status =
            'Ã‚Â¡REPARACIÃƒâ€œN COMPLETADA! ($total usuarios actualizados)';
        _isRepairing = false;
      });
    } on Exception catch (e) {
      setState(() {
        _status = 'Error crÃƒÂ­tico: $e';
        _isRepairing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mantenimiento Base de Datos'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const Icon(Icons.build_circle, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Reparador de BÃƒÂºsqueda',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Esta herramienta regenerarÃƒÂ¡ el campo 'keywords' de todos los usuarios eliminando los acentos. Esto permitirÃƒÂ¡ que 'Jose' encuentre a 'JosÃƒÂ©'.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            if (_isRepairing) ...<Widget>[
              LinearProgressIndicator(value: _progress, color: Colors.orange),
              const SizedBox(height: 10),
              Text(_status),
            ] else ...<Widget>[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _ejecutarReparacion,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('EJECUTAR REPARACIÃƒâ€œN AHORA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _status,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
            const Divider(height: 40),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (BuildContext c, int i) => Text(
                    _logs[i],
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
