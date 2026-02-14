import 'package:flutter/material.dart';

class SalufitUtils {
  // Lógica centralizada de IDs
  static List<dynamic> getPosiblesIds(String userId) {
    final idConCeros = userId.padLeft(6, '0');
    final idSinCeros = userId.replaceFirst(RegExp('^0+'), '');

    final ids = <dynamic>[idConCeros, idSinCeros];

    // Añadimos la versión numérica si es posible
    if (int.tryParse(idSinCeros) != null) {
      ids.add(int.parse(idSinCeros));
    }

    return ids;
  }

  // Lógica centralizada de Colores de Clases
  static MaterialColor getColorPorClase(String nombreClase) {
    final nombre = nombreClase.toLowerCase();
    if (nombre.contains('entrenamiento')) return Colors.red;
    if (nombre.contains('meditación') || nombre.contains('meditacion')) {
      return Colors.blueGrey;
    }
    return Colors.blue;
  }
}
