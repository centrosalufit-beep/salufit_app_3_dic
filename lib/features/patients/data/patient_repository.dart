// lib/features/patients/data/patient_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// Importamos el modelo donde hemos definido la extensión .toPatient()
import 'package:salufit_app/features/patients/domain/patient_model.dart';

part 'patient_repository.g.dart';

@riverpod
PatientRepository patientRepository(Ref ref) {
  return PatientRepository(FirebaseFirestore.instance);
}

class PatientRepository {
  PatientRepository(this._firestore);
  final FirebaseFirestore _firestore;

  Future<List<Patient>> getLegacyPatients() async {
    try {
      final snapshot = await _firestore
          .collection('legacy_import')
          .orderBy('importedAt', descending: true)
          .get();

      // CORRECCIÓN: Usamos <Patient> explícitamente y la extensión .toPatient()
      return snapshot.docs.map<Patient>((doc) => doc.toPatient()).toList();
    } catch (e) {
      throw Exception('Error al cargar pacientes: $e');
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('legacy_import')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: '${query.toLowerCase()}z')
          .get();

      // CORRECCIÓN: Tipado explícito aquí también
      return snapshot.docs.map<Patient>((doc) => doc.toPatient()).toList();
    } catch (e) {
      return [];
    }
  }
}
