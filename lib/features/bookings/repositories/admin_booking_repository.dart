// lib/features/bookings/repositories/admin_booking_repository.dart

import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:salufit_app/core/config/app_config.dart';

class AdminBookingRepository {
  AdminBookingRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<AdminGenResult> generarCalendario({
    required String nombreClase,
    required String profesional,
    required List<int> diasSemana,
    required int hora,
    required int minutos,
    required int mes, // 0-11
    required int anio,
    int aforoMax = 12,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final token = await user.getIdToken();

    // Las variables 'totalCreated' y 'errors' se han eliminado porque
    // este método maneja una sola petición. El bucle estará en la capa superior.

    try {
      final body = jsonEncode({
        'nombre': nombreClase,
        'profesional': profesional,
        'diasSemana': diasSemana,
        'hora': hora,
        'minutos': minutos,
        'mes': mes,
        'anio': anio,
        'aforoMax': aforoMax,
      });

      final response = await _client.post(
        Uri.parse(AppConfig.urlGenerarClases),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AdminGenResult(success: true);
      } else {
        return AdminGenResult(
          success: false,
          error: 'Error ${response.statusCode}',
        );
      }
    } on SocketException {
      return AdminGenResult(success: false, error: 'Sin conexión');
    } on Exception catch (e) {
      return AdminGenResult(success: false, error: e.toString());
    }
  }
}

/// Clase simple para devolver resultados a la UI sin exponer HTTP
class AdminGenResult {
  AdminGenResult({required this.success, this.error});
  // CORRECCIÓN: Propiedades primero, constructor después
  final bool success;
  final String? error;
}
