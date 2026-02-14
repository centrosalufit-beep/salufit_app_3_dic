// lib/features/bookings/domain/models/class_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  // 2. CONSTRUCTOR PRINCIPAL
  ClassModel({
    required this.id,
    required this.name,
    required this.instructor,
    required this.startTime,
    required this.maxCapacity,
    required this.currentCapacity,
    required this.attendees,
  });

  // 3. FACTORY: Agnóstico a la fuente (Testing & Robustez)
  factory ClassModel.fromMap(Map<String, dynamic> data, String docId) {
    return ClassModel(
      id: docId,
      // Manejo seguro: Si no es String, intenta convertirlo. Si es nulo, usa default.
      name: _parseString(data['nombre'], 'Clase sin nombre'),
      instructor: _parseString(data['monitor'], 'Salufit'),

      // Manejo seguro de fechas (Timestamp, String o Null)
      startTime: _parseDate(data['fechaHoraInicio']),

      // Manejo seguro de números (int, double, String numérico o basura)
      maxCapacity: _parseInt(data['aforoMaximo'], 12),
      currentCapacity: _parseInt(data['aforoActual'], 0),

      // Manejo seguro de listas (List, null, o tipo incorrecto)
      attendees: _parseList(data['asistentes']),
    );
  }

  // 4. FACTORY: Firestore
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClassModel.fromMap(data, doc.id);
  }
  // 1. DEFINICIÓN DE CAMPOS
  final String id;
  final String name;
  final String instructor;
  final DateTime startTime;
  final int maxCapacity;
  final int currentCapacity;
  final List<String> attendees;

  // ---------------------------------------------------------------------------
  // 🛡️ MÉTODOS PRIVADOS DE SEGURIDAD (HELPERS)
  // ---------------------------------------------------------------------------

  /// Convierte cualquier cosa a String de forma segura
  static String _parseString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    // Si llega un int/double (ej: nombre: 12345), lo convertimos a texto para no romper la UI
    return value.toString();
  }

  /// Intenta extraer un entero de cualquier input (num o String)
  static int _parseInt(dynamic value, int defaultValue) {
    if (value is num) return value.toInt(); // Maneja int y double
    if (value is String) {
      // Intenta parsear "10", si es "veinte" devuelve null -> defaultValue
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Convierte Timestamps o Strings a DateTime
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Asegura que siempre devolvemos una List<String> válida
  static List<String> _parseList(dynamic value) {
    if (value is List) {
      // Mapeamos cada elemento a String por seguridad (evita crash si hay un int en la lista)
      return value.map((e) => e.toString()).toList();
    }
    return []; // Si llega un String u otro objeto, devolvemos lista vacía
  }
}
