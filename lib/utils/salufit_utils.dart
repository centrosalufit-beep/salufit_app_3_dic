import 'package:flutter/material.dart';

class SalufitUtils {
  // Lógica centralizada de IDs
  static List<dynamic> getPosiblesIds(String userId) {
    final String idConCeros = userId.padLeft(6, '0');
    final String idSinCeros = userId.replaceFirst(RegExp(r'^0+'), '');
    
    final List<dynamic> ids = [idConCeros, idSinCeros];
    
    // Añadimos la versión numérica si es posible
    if (int.tryParse(idSinCeros) != null) {
      ids.add(int.parse(idSinCeros));
    }
    
    return ids;
  }

  // Lógica centralizada de Colores de Clases
  static MaterialColor getColorPorClase(String nombreClase) {
    final String nombre = nombreClase.toLowerCase(); 
    if (nombre.contains('entrenamiento')) return Colors.red; 
    if (nombre.contains('meditación') || nombre.contains('meditacion')) return Colors.blueGrey; 
    return Colors.blue; 
  }
}