// FILE: lib/services/staff_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salufit_app/core/config/app_config.dart';

class StaffService {
  factory StaffService() => _instance;
  StaffService._internal();
  static final StaffService _instance = StaffService._internal();

  /// Maneja toda la lógica de fichaje
  Future<Map<String, dynamic>> registrarFichaje({
    required String userId,
    required String type,
    String? manualTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw const ApiServiceException(
        message: 'Sesión no válida. Reinicia la app.',
      );
    }

    // 1. Obtener Info del Dispositivo
    var deviceId = 'unknown_device';
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        deviceId = (await deviceInfo.androidInfo).id;
      } else if (Platform.isIOS) {
        deviceId =
            (await deviceInfo.iosInfo).identifierForVendor ?? 'unknown_ios';
      }
    } catch (_) {}

    // 2. Validar WiFi
    String? wifiSsid;
    if (manualTime == null) {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
      }

      if (status.isGranted) {
        try {
          wifiSsid = await NetworkInfo().getWifiName();
          wifiSsid = wifiSsid?.replaceAll('"', '').trim();
        } catch (_) {}
      }

      if (wifiSsid != AppConfig.wifiPermitida) {
        throw WifiException(
          currentWifi: wifiSsid,
          requiredWifi: AppConfig.wifiPermitida,
        );
      }
    }

    // 3. Llamada API
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse(AppConfig.urlFichar),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String?>{
        'userId': userId,
        'userEmail': user.email,
        'type': type,
        'deviceId': deviceId,
        'wifiSsid': wifiSsid,
        'manualTime': manualTime,
      }),
    );

    // Casting seguro y explícito
    final dynamic decoded = jsonDecode(response.body);
    final data = (decoded as Map<dynamic, dynamic>).cast<String, dynamic>();

    if (response.statusCode == 200) {
      return data;
    } else {
      throw ApiServiceException(
        message: (data['error'] as String?) ?? 'Error desconocido',
        code: data['code'] as String?,
        data: data,
      );
    }
  }
}

class WifiException implements Exception {
  WifiException({required this.requiredWifi, this.currentWifi});
  final String? currentWifi;
  final String requiredWifi;
}

class ApiServiceException implements Exception {
  const ApiServiceException({required this.message, this.code, this.data});
  final String message;
  final String? code;
  final Map<String, dynamic>? data;
  @override
  String toString() => message;
}
