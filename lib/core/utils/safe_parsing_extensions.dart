import 'package:cloud_firestore/cloud_firestore.dart';

/// Extensiones de "Grado Militar" para el parseo seguro de datos.
/// Elimina la necesidad de casting manual y previene errores de tipo en tiempo de ejecución.
///
/// Uso:
/// final name = data.safeString('name', defaultValue: 'Usuario');
/// final date = data.safeDateTime('created_at');
extension SafeParsing on Map<String, dynamic>? {
  /// Recupera un String de forma segura.
  /// Convierte números y booleanos a String automáticamente si es necesario.
  String safeString(String key, {String defaultValue = ''}) {
    if (this == null) return defaultValue;
    final value = this![key];

    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();

    return defaultValue;
  }

  /// Recupera un int de forma segura.
  /// Intenta parsear Strings numéricos y redondea doubles.
  int safeInt(String key, {int defaultValue = 0}) {
    if (this == null) return defaultValue;
    final value = this![key];

    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is bool) return value ? 1 : 0;

    return defaultValue;
  }

  /// Recupera un double de forma segura.
  /// Maneja enteros convirtiéndolos a punto flotante.
  double safeDouble(String key, {double defaultValue = 0.0}) {
    if (this == null) return defaultValue;
    final value = this![key];

    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Maneja comas como separadores decimales si es necesario (locale-check simple)
      final normalized = value.replaceAll(',', '.');
      return double.tryParse(normalized) ?? defaultValue;
    }

    return defaultValue;
  }

  /// Recupera un bool de forma segura.
  /// Interpreta 1/0 y strings "true"/"false" (case insensitive).
  bool safeBool(String key, {bool defaultValue = false}) {
    if (this == null) return defaultValue;
    final value = this![key];

    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }

    return defaultValue;
  }

  /// Recupera un DateTime de forma segura.
  /// Maneja [Timestamp] de Firebase, Strings ISO-8601 y milisegundos (int).
  DateTime safeDateTime(String key, {DateTime? defaultValue}) {
    final defaultDate = defaultValue ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (this == null) return defaultDate;
    final value = this![key];

    if (value == null) return defaultDate;

    // Manejo prioritario de Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value) ?? defaultDate;
    }

    if (value is int) {
      // Asumimos milisegundos si el número es grande, sino segundos (Unix epoch)
      // Un timestamp de 10 dígitos es segundos (hasta el año 2286)
      if (value > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    return defaultDate;
  }

  /// Recupera una Lista tipada de forma segura.
  /// [mapper] transforma cada elemento dynamic al tipo [T].
  List<T> safeList<T>(
    String key,
    T Function(dynamic e) mapper, {
    List<T> defaultValue = const <Never>[],
  }) {
    if (this == null) return defaultValue;
    final value = this![key];

    if (value == null) return defaultValue;

    if (value is List) {
      try {
        return value.map((e) => mapper(e)).toList();
      } on Exception catch (e) {
        // En caso de error en el mapeo de un elemento, retornamos default para seguridad
        // Opcionalmente se podría filtrar el elemento corrupto.
        return defaultValue;
      }
    }

    return defaultValue;
  }

  /// Recupera un Map anidado de forma segura.
  Map<String, dynamic> safeMap(
    String key, {
    Map<String, dynamic> defaultValue = const <String, dynamic>{},
  }) {
    if (this == null) return defaultValue;
    final value = this![key];

    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (_) {
        return defaultValue;
      }
    }

    return defaultValue;
  }
}
