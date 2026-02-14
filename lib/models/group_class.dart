import 'package:cloud_firestore/cloud_firestore.dart';

class GroupClass {
  const GroupClass({
    required this.id,
    required this.nombre,
    required this.monitor,
    required this.horario,
    required this.aforoActual,
    required this.aforoMaximo,
  });

  factory GroupClass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    // --- 1. LÓGICA PARA FORMATEAR LA HORA ---
    var horarioFormateado = 'Sin hora';

    if (data['fechaHoraInicio'] != null) {
      // Zero-Dynamic: Casting explícito de Timestamp
      final timestamp = data['fechaHoraInicio'] as Timestamp;
      final date = timestamp.toDate();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      horarioFormateado = '$hour:$minute';
    }

    // --- 2. MAPEO SEGURO ---
    return GroupClass(
      id: doc.id,
      // Zero-Dynamic: Casting explícito
      nombre: (data['nombreClase'] as String?) ?? 'Clase sin nombre',
      monitor: (data['profesionalId'] as String?) ?? 'Monitor por asignar',
      aforoActual: (data['aforoActual'] as int?) ?? 0,
      aforoMaximo: (data['aforoMax'] as int?) ?? 10,
      horario: horarioFormateado,
    );
  }

  final String id;
  final String nombre;
  final String monitor;
  final String horario;
  final int aforoActual;
  final int aforoMaximo;
}
