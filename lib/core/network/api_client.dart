// lib/core/network/api_client.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Necesario para el Provider
import 'package:http/http.dart' as http;
import 'package:salufit_app/core/config/app_config.dart';

// Definición del Provider para Inyección de Dependencias
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message (Code: $statusCode)';
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(url);

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.apiTimeout);

      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(
        'La conexión ha tardado demasiado. Verifica tu internet.',
      );
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error de Red en $url: $e');
      throw ApiException('Error de conexión: $e');
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException(
          'Error al procesar respuesta del servidor (JSON malformado)',
        );
      }
    } else {
      var errorMsg = 'Error del servidor (${response.statusCode})';

      try {
        if (response.body.isNotEmpty) {
          final dynamic body = jsonDecode(response.body);
          if (body is Map) {
            if (body.containsKey('error') && body['error'] is String) {
              errorMsg = body['error'] as String;
            } else if (body.containsKey('message') &&
                body['message'] is String) {
              errorMsg = body['message'] as String;
            }
          }
        }
      } catch (_) {
        // Fallback silencioso
      }

      throw ApiException(errorMsg, response.statusCode);
    }
  }
}
