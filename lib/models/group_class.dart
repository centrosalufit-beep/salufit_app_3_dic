import 'package:cloud_firestore/cloud_firestore.dart';

class GroupClass {
  final String id;
  final String nombre;
  final String monitor;
  final String horario;
  final int aforoActual;
  final int aforoMaximo;

  GroupClass({
    required this.id,
    required this.nombre,
    required this.monitor,
    required this.horario,
    required this.aforoActual,
    required this.aforoMaximo,
  });

  factory GroupClass.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // --- 1. LÓGICA PARA FORMATEAR LA HORA ---
    // Convertimos el Timestamp de Firebase (fecha y hora) a un texto bonito "10:00"
    String horarioFormateado = 'Sin hora';
    
    if (data['fechaHoraInicio'] != null) {
      Timestamp timestamp = data['fechaHoraInicio'];
      DateTime date = timestamp.toDate();
      // Truco para que salga "10:00" en vez de "10:0" (añade ceros si hace falta)
      String hour = date.hour.toString().padLeft(2, '0');
      String minute = date.minute.toString().padLeft(2, '0');
      horarioFormateado = '$hour:$minute';
    }

    // --- 2. MAPEO DE TUS CAMPOS REALES ---
    return GroupClass(
      id: doc.id,
      // Aquí conectamos TUS nombres de Firebase con los de la App:
      nombre: data['nombreClase'] ?? 'Clase sin nombre', 
      monitor: data['profesionalId'] ?? 'Monitor por asignar', 
      aforoActual: data['aforoActual'] ?? 0,
      // Fíjate que tú usas 'aforoMax' en vez de 'aforoMaximo'
      aforoMaximo: data['aforoMax'] ?? 10, 
      horario: horarioFormateado,
    );
  }
}