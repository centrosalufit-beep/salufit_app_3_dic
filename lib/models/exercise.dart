import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id;
  final String nombre;
  final int orden;
  final int codigoInterno;
  final String descripcion;
  final String area;
  final String etiquetas; // Lo tratamos como texto simple por ahora
  final String urlVideo;
  final bool activo;

  Exercise({
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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      nombre: data['nombre'] ?? 'Ejercicio sin nombre',
      orden: data['orden'] ?? 0,
      codigoInterno: data['codigoInterno'] ?? 0,
      descripcion: data['descripcion'] ?? '',
      area: data['area'] ?? 'General',
      // Si guardaste las etiquetas como Array, esto las convierte a texto separado por comas
      etiquetas: data['etiquetas'] is List 
          ? (data['etiquetas'] as List).join(', ') 
          : data['etiquetas'] ?? '',
      urlVideo: data['urlVideo'] ?? '',
      activo: data['activo'] ?? true,
    );
  }
}