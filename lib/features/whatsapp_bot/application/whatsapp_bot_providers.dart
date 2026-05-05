import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/clinni_appointment_model.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/whatsapp_conversation_model.dart';

part 'whatsapp_bot_providers.g.dart';

/// Las Cloud Functions de import son onRequest (HTTP) en lugar de onCall
/// porque cloud_functions plugin de Flutter no soporta Windows desktop.
/// Usamos HTTP directo con Firebase Auth ID token en header Authorization.
const _cfBaseUrl = 'https://europe-southwest1-salufitnewapp.cloudfunctions.net';

Future<Map<String, dynamic>> _postCloudFunction(
  String functionName,
  Map<String, dynamic> body,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StateError('No hay usuario autenticado');
  }
  final idToken = await user.getIdToken();
  final url = Uri.parse('$_cfBaseUrl/$functionName');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );
  final raw = response.body.isEmpty ? '{}' : response.body;
  final data = jsonDecode(raw) as Map<String, dynamic>;
  if (response.statusCode != 200) {
    final err = data['error']?.toString() ?? 'HTTP ${response.statusCode}';
    throw StateError(err);
  }
  return data;
}

/// Stream con las conversaciones más recientes del bot, ordenadas por
/// la última interacción (descendente). Limit 100 para no saturar la UI.
@riverpod
Stream<List<WhatsAppConversation>> whatsappConversations(Ref ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('whatsapp_conversations')
      .orderBy('fechaUltimaInteraccion', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map(WhatsAppConversation.fromFirestore)
            .toList(),
      );
}

/// Citas activas (futuras o de hoy) en `clinni_appointments`,
/// ordenadas por fecha ascendente. Limit 200.
@riverpod
Stream<List<ClinniAppointment>> upcomingAppointments(Ref ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  final today = DateTime.now().subtract(const Duration(hours: 12));
  return db
      .collection('clinni_appointments')
      .where('fechaCita', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
      .orderBy('fechaCita')
      .limit(200)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(ClinniAppointment.fromFirestore).toList(),
      );
}

/// Configuración del bot (`config/whatsapp_bot`). Si no existe, devuelve null.
@riverpod
Stream<Map<String, dynamic>?> botConfig(Ref ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('config')
      .doc('whatsapp_bot')
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
}

/// Resultado de `importClinniAppointments` Cloud Function.
class ImportResult {
  const ImportResult({
    required this.imported,
    required this.duplicates,
    required this.errors,
    required this.errorMessages,
  });

  factory ImportResult.fromMap(Map<String, dynamic> map) {
    return ImportResult(
      imported: (map['imported'] as num?)?.toInt() ?? 0,
      duplicates: (map['duplicates'] as num?)?.toInt() ?? 0,
      errors: (map['errors'] as num?)?.toInt() ?? 0,
      errorMessages: ((map['errorMessages'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  final int imported;
  final int duplicates;
  final int errors;
  final List<String> errorMessages;
}

/// Llama a la Cloud Function `importClinniAppointments` (onRequest) con el
/// contenido del Excel codificado en base64. Usa http POST con Firebase Auth
/// ID token en header Authorization Bearer (cloud_functions plugin no
/// soporta Windows desktop).
@riverpod
Future<ImportResult> importClinniExcel(
  Ref ref, {
  required String fileBase64,
  required String fileName,
}) async {
  final data = await _postCloudFunction('importClinniAppointments', {
    'fileBase64': fileBase64,
    'fileName': fileName,
  });
  return ImportResult.fromMap(data);
}

/// Resultado de `importClinniPatients` (idempotente: imported = nuevos
/// creados, updated = existentes sobrescritos por mismo telefono).
class ImportPatientsResult {
  const ImportPatientsResult({
    required this.imported,
    required this.updated,
    required this.errors,
    required this.errorMessages,
  });

  factory ImportPatientsResult.fromMap(Map<String, dynamic> map) {
    return ImportPatientsResult(
      imported: (map['imported'] as num?)?.toInt() ?? 0,
      updated: (map['updated'] as num?)?.toInt() ?? 0,
      errors: (map['errors'] as num?)?.toInt() ?? 0,
      errorMessages: ((map['errorMessages'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  final int imported;
  final int updated;
  final int errors;
  final List<String> errorMessages;
}

/// Llama a la Cloud Function `importClinniPatients` (onRequest) con el
/// contenido del Excel `listado_v26.xlsx` codificado en base64.
@riverpod
Future<ImportPatientsResult> importClinniPatientsExcel(
  Ref ref, {
  required String fileBase64,
  required String fileName,
}) async {
  final data = await _postCloudFunction('importClinniPatients', {
    'fileBase64': fileBase64,
    'fileName': fileName,
  });
  return ImportPatientsResult.fromMap(data);
}

/// Llama a `sendReagendarConfirmation`: avisa al paciente vía template Meta
/// `confirmacion_reagendado` que recepción ya cerró su cambio de cita,
/// y marca la conversación como resuelta.
Future<void> sendReagendarConfirmation(String conversationId) async {
  await _postCloudFunction('sendReagendarConfirmation', {
    'conversationId': conversationId,
  });
}

/// Llama a `triggerReminderHttp`: fuerza el reenvío del recordatorio
/// para una cita concreta. Ignora la ventana T-24h y resetea el flag
/// `recordatorioEnviado` para que el cron lo re-procese inmediatamente.
Future<Map<String, dynamic>> triggerReminderHttp(String appointmentId) async {
  final data = await _postCloudFunction('triggerReminderHttp', {
    'appointmentId': appointmentId,
  });
  return data;
}
