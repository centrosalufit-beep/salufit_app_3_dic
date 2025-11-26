import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDatabaseRepairScreen extends StatefulWidget {
  const AdminDatabaseRepairScreen({super.key});

  @override
  State<AdminDatabaseRepairScreen> createState() => _AdminDatabaseRepairScreenState();
}

class _AdminDatabaseRepairScreenState extends State<AdminDatabaseRepairScreen> {
  bool _isLoading = false;
  String _status = "Listo para reparar";
  double _progress = 0.0;
  List<String> _logs = [];

  // --- FUNCIÓN DE LIMPIEZA (La misma que usamos en el buscador) ---
  String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  // --- GENERADOR DE KEYWORDS POTENTE ---
  List<String> _generateKeywords(String nombre, String id) {
    List<String> keywords = [];
    
    // 1. Limpiamos el nombre (minusculas y sin acentos)
    String nombreLimpio = removeDiacritics(nombre.toLowerCase().trim());
    
    // 2. Separamos por palabras (ej: "jose", "baydal", "munera")
    List<String> palabras = nombreLimpio.split(RegExp(r'\s+'));
    
    // 3. Añadimos cada palabra individual
    keywords.addAll(palabras);
    
    // 4. Añadimos variantes del ID
    String idSinCeros = id.replaceFirst(RegExp(r'^0+'), '');
    keywords.add(id.toLowerCase());
    if (idSinCeros.isNotEmpty) keywords.add(idSinCeros);

    // 5. OPCIONAL: Añadimos combinaciones (ej: "jose baydal") si quieres búsquedas exactas
    // keywords.add(nombreLimpio);

    return keywords.toSet().toList(); // Eliminamos duplicados
  }

  Future<void> _repararBaseDeDatos() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _status = "Iniciando escaneo...";
      _progress = 0;
    });

    try {
      // 1. Descargar TODOS los usuarios
      var snapshot = await FirebaseFirestore.instance.collection('users').get();
      int total = snapshot.docs.length;
      int procesados = 0;
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String nombre = (data['nombreCompleto'] ?? data['nombre'] ?? "").toString();
        String id = doc.id;

        if (nombre.isEmpty) continue;

        // 2. Generar las nuevas keywords LIMPIAS
        List<String> newKeywords = _generateKeywords(nombre, id);

        // 3. Añadir al lote de actualización
        batch.update(doc.reference, {'keywords': newKeywords});
        
        _logs.add("✅ $nombre -> $newKeywords");
        batchCount++;
        procesados++;

        // Firebase limita los batches a 500 operaciones
        if (batchCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCount = 0;
        }

        // Actualizar barra de progreso visual
        setState(() {
          _progress = procesados / total;
          _status = "Procesando $procesados de $total...";
        });
      }

      // Comitear los restantes
      if (batchCount > 0) await batch.commit();

      setState(() {
        _status = "¡REPARACIÓN COMPLETADA! ($total usuarios actualizados)";
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _status = "Error crítico: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mantenimiento Base de Datos"), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.build_circle, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Reparador de Búsqueda",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Esta herramienta regenerará el campo 'keywords' de todos los usuarios eliminando los acentos. Esto permitirá que 'Jose' encuentre a 'José'.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            if (_isLoading) ...[
              LinearProgressIndicator(value: _progress, color: Colors.orange),
              const SizedBox(height: 10),
              Text(_status),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _repararBaseDeDatos,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("EJECUTAR REPARACIÓN AHORA"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(_status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],

            const Divider(height: 40),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(5)),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (c, i) => Text(_logs[i], style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}