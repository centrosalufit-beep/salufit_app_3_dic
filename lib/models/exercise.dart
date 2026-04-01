import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.codigoInterno,
    required this.descripcion,
    required this.area,
    required this.etiquetas,
    required this.urlVideo,
    required this.activo,
  });

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      // Zero-Dynamic: Casting explícito
      nombre: (data['nombre'] as String?) ?? 'Ejercicio sin nombre',
      orden: (data['orden'] as int?) ?? 0,
      codigoInterno: (data['codigoInterno'] as int?) ?? 0,
      descripcion: (data['descripcion'] as String?) ?? '',
      area: (data['familia'] as String?) ?? (data['area'] as String?) ?? 'General',
      // Lógica de lista segura
      etiquetas: data['etiquetas'] is List
          ? (data['etiquetas'] as List).join(', ')
          : (data['etiquetas'] as String?) ?? '',
      urlVideo: (data['urlVideo'] as String?) ?? '',
      activo: (data['activo'] as bool?) ?? true,
    );
  }

  final String id;
  final String nombre;
  final int orden;
  final int codigoInterno;
  final String descripcion;
  final String area;
  final String etiquetas;
  final String urlVideo;
  final bool activo;
}
