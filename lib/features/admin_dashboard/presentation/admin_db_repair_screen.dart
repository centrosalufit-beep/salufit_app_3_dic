import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDatabaseRepairScreen extends StatefulWidget {
  const AdminDatabaseRepairScreen({super.key});
  @override
  State<AdminDatabaseRepairScreen> createState() =>
      _AdminDatabaseRepairScreenState();
}

class _AdminDatabaseRepairScreenState extends State<AdminDatabaseRepairScreen> {
  bool _isLoading = false;
  String _status = 'Listo para reparar';
  double _progress = 0;

  String removeDiacritics(String str) {
    var result = str;
    const withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (var i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  List<String> _generateKeywords(String n, String i) {
    final cleanN = removeDiacritics(n.toLowerCase());
    return [cleanN, i, ...cleanN.split(' ')];
  }

  Future<void> _repararBaseDeDatos() async {
    setState(() {
      _isLoading = true;
      _status = 'Iniciando...';
      _progress = 0;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('activado', isEqualTo: true)
          .get();
      final total = snapshot.docs.length;
      var batch = FirebaseFirestore.instance.batch();
      var count = 0;
      var processed = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // CASTING EXPLÍCITO para evitar error de argument_type_not_assignable
        final keywords = _generateKeywords(
          (data['nombre'] ?? '') as String,
          (data['dni'] ?? '') as String,
        );

        batch.update(doc.reference, {'keywords': keywords});

        count++;
        processed++;

        if (count >= 400 || processed == total) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
          if (mounted) {
            setState(() {
              _progress = processed / total;
              _status = 'Procesando $processed / $total...';
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Completado ($total registros)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mantenimiento DB (Optimizado)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            if (_isLoading) ...[
              CircularProgressIndicator(value: _progress),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ] else
              ElevatedButton(
                onPressed: _repararBaseDeDatos,
                child: const Text('EJECUTAR REPARACIÓN'),
              ),
          ],
        ),
      ),
    );
  }
}
