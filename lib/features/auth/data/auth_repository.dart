import 'dart:convert';

// --- AGREGADO ESTE IMPORT ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

// Este archivo se generará automáticamente después
part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

class AuthRepository {
  Future<void> sendOTP(String userId) async {
    final uri = Uri.parse(AppConfig.urlOtpEnviar);

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'userId': userId}),
      );

      _validateResponse(response);
    } on Exception catch (e) {
      throw Exception('Error al enviar código: $e');
    }
  }

  Future<void> activateAccount({
    required String userId,
    required String code,
  }) async {
    final uri = Uri.parse(AppConfig.urlActivarCuenta);

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'userId': userId,
          'code': code,
        }),
      );

      _validateResponse(response);
    } on Exception catch (e) {
      throw Exception('Error de activación: $e');
    }
  }

  void _validateResponse(http.Response response) {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'La respuesta del servidor no es un Mapa válido JSON',
      );
    }

    if (response.statusCode != 200) {
      final errorMsg = decoded.safeString(
        'error',
        defaultValue: 'Error desconocido del servidor',
      );
      throw Exception(errorMsg);
    }

    if (decoded.containsKey('success') && !decoded.safeBool('success')) {
      final msg = decoded.safeString(
        'message',
        defaultValue: 'Operación fallida',
      );
      throw Exception(msg);
    }
  }
}
