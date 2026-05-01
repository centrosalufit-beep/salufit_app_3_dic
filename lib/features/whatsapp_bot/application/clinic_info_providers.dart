import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/clinic_info_model.dart';

/// Stream del documento `config/clinic_info`. Si no existe devuelve un
/// ClinicInfo con valores por defecto vacíos.
final clinicInfoProvider = StreamProvider<ClinicInfo>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db.collection('config').doc('clinic_info').snapshots().map((doc) {
    if (!doc.exists) return const ClinicInfo();
    return ClinicInfo.fromFirestore(doc);
  });
});

/// Stream de festivos próximos (desde hoy hasta dentro de 12 meses),
/// ordenados por fecha ascendente.
final clinicHolidaysProvider = StreamProvider<List<ClinicHoliday>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  final today = DateTime.now()
      .toIso8601String()
      .substring(0, 10);
  return db
      .collection('clinic_holidays')
      .where('fecha', isGreaterThanOrEqualTo: today)
      .orderBy('fecha')
      .snapshots()
      .map((snap) => snap.docs.map(ClinicHoliday.fromFirestore).toList());
});

/// Stream de ausencias activas y futuras de profesionales.
final professionalAbsencesProvider =
    StreamProvider<List<ProfessionalAbsence>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  final now = Timestamp.now();
  return db
      .collection('professional_absences')
      .where('hasta', isGreaterThanOrEqualTo: now)
      .orderBy('hasta')
      .snapshots()
      .map((snap) => snap.docs.map(ProfessionalAbsence.fromFirestore).toList());
});

/// Acciones de escritura. No usamos riverpod_generator aquí para evitar
/// regenerar; son funciones simples que llaman a Firestore directamente.
class ClinicInfoActions {
  ClinicInfoActions(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> updateClinicInfo(Map<String, dynamic> partial) async {
    final uid = _auth.currentUser?.uid;
    await _db.collection('config').doc('clinic_info').set({
      ...partial,
      'lastUpdatedBy': uid,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertHoliday(ClinicHoliday h) async {
    final data = <String, dynamic>{
      'fecha': h.fecha,
      'motivo': h.motivo,
      'tipo': h.tipo,
      if (h.horarioEspecial != null)
        'horarioEspecial': {
          'abre': h.horarioEspecial!.abre,
          'cierra': h.horarioEspecial!.cierra,
        },
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
    await _db.collection('clinic_holidays').doc(h.fecha).set(data);
  }

  Future<void> deleteHoliday(String fechaIso) async {
    await _db.collection('clinic_holidays').doc(fechaIso).delete();
  }

  Future<void> addAbsence({
    required String profesionalId,
    required String profesionalNombre,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    await _db.collection('professional_absences').add({
      'profesionalId': profesionalId,
      'profesionalNombre': profesionalNombre,
      'desde': Timestamp.fromDate(desde),
      'hasta': Timestamp.fromDate(hasta),
      'motivo': motivo,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAbsence(String id) async {
    await _db.collection('professional_absences').doc(id).delete();
  }
}

final clinicInfoActionsProvider = Provider<ClinicInfoActions>((ref) {
  return ClinicInfoActions(
    ref.watch(firebaseFirestoreProvider),
    FirebaseAuth.instance,
  );
});

/// Lista de profesionales para el dropdown de Ausencias.
final professionalsListProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db.collection('professional_schedules').snapshots().map((snap) {
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'nombre': (data['nombre'] as String?) ?? d.id,
        'activo': data['activo'] as bool? ?? true,
      };
    }).toList();
  });
});
