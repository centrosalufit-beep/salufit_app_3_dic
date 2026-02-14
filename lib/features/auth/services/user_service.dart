// lib/features/auth/services/user_service.dart

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class UserService {
  // Singleton
  factory UserService() => _instance;
  UserService._internal();
  static final UserService _instance = UserService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> reclamarPremio([String? premioEspecifico]) async {
    final premios = <String>[
      '50% Dto. en Higiene Dental',
      '50% Dto. en Sesión Presoterapia',
      '50% Dto. en Sesión Indiba',
      '50% Dto. en Sesión NESA',
      'Medición Corporal GRATUITA',
    ];

    final premio =
        premioEspecifico ?? premios[Random().nextInt(premios.length)];

    final mensaje =
        '¡Hola! He completado mis sesiones del mes y quiero canjear mi premio: $premio';

    // AppConfig.urlWhatsApp ya incluye la base, añadimos parámetros
    final urlString =
        '${AppConfig.urlWhatsApp}?text=${Uri.encodeComponent(mensaje)}';
    final url = Uri.parse(urlString);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }

  Future<void> abrirPrivacidad() async {
    final url = Uri.parse(AppConfig.urlPrivacidad);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir el navegador');
    }
  }

  // --- Secure Storage ---

  Future<void> saveSecureToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (e) {
      await _handleStorageError(e);
    }
  }

  Future<String?> getSecureToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      await _handleStorageError(e);
      return null;
    }
  }

  Future<void> deleteSecureToken() async {
    try {
      await _storage.delete(key: 'auth_token');
    } catch (e) {
      debugPrint('Error al borrar token: $e');
    }
  }

  Future<void> _handleStorageError(Object e) async {
    debugPrint('SecureStorage Error: $e');
  }
}
