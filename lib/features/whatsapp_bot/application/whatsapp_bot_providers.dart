import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/clinni_appointment_model.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/whatsapp_conversation_model.dart';

part 'whatsapp_bot_providers.g.dart';

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

/// Llama a la Cloud Function `importClinniAppointments` con el contenido
/// del Excel codificado en base64.
@riverpod
Future<ImportResult> importClinniExcel(
  Ref ref, {
  required String fileBase64,
  required String fileName,
}) async {
  final functions = FirebaseFunctions.instanceFor(region: 'europe-southwest1');
  final callable = functions.httpsCallable('importClinniAppointments');
  final response = await callable.call<Map<Object?, Object?>>({
    'fileBase64': fileBase64,
    'fileName': fileName,
  });
  final data = Map<String, dynamic>.from(response.data);
  return ImportResult.fromMap(data);
}
