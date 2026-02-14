// lib/features/patient_record/providers/material_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// Importamos el provider de ID que definimos o existe en auth
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================================================================
// 1. GESTOR DE PROGRESO DIARIO
// ==================================================================
class DailyProgressNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _loadProgress();
    return <String>{};
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastSavedDate = prefs.getString('material_last_date');

      if (lastSavedDate != todayKey) {
        await prefs.setString('material_last_date', todayKey);
        await prefs.setStringList('material_completed_ids', <String>[]);
        state = <String>{};
      } else {
        final saved =
            prefs.getStringList('material_completed_ids') ?? <String>[];
        state = saved.toSet();
      }
    } catch (_) {
      state = <String>{};
    }
  }

  Future<void> markAsDone(String assignmentId) async {
    if (state.contains(assignmentId)) return;

    state = <String>{...state, assignmentId};

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('material_completed_ids', state.toList());
    } catch (_) {}
  }
}

final NotifierProvider<DailyProgressNotifier, Set<String>>
    dailyProgressProvider =
    NotifierProvider<DailyProgressNotifier, Set<String>>(
  DailyProgressNotifier.new,
);

// ==================================================================
// 2. STREAM DE EJERCICIOS ASIGNADOS
// ==================================================================
final AutoDisposeStreamProvider<List<DocumentSnapshot<Object?>>>
    myAssignmentsProvider =
    StreamProvider.autoDispose<List<DocumentSnapshot<Object?>>>((Ref ref) {
  // CORRECCIÓN DE SEGURIDAD: Usar ID, no Email.
  final userId = ref.watch(
    currentUserIdProvider,
  ); // Asegúrate de importar esto de auth_providers

  if (userId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('exercise_assignments')
      .where('userId', isEqualTo: userId) // <-- CAMBIO A userId
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs);
});

// ==================================================================
// 3. BUSCADOR DE DETALLES MAESTROS
// ==================================================================
final AutoDisposeFutureProviderFamily<Map<String, String?>, String?>
    exerciseDetailsProvider =
    FutureProvider.family.autoDispose<Map<String, String?>, String?>((
  Ref ref,
  String? exerciseId,
) async {
  if (exerciseId == null || exerciseId.isEmpty) {
    return <String, String?>{'video': null, 'titulo': null};
  }

  try {
    final docRef =
        FirebaseFirestore.instance.collection('exercises').doc(exerciseId);
    final docSnapshot = await docRef.get();

    Map<String, dynamic>? data;

    if (docSnapshot.exists) {
      data = docSnapshot.data();
    } else {
      final idNum = int.tryParse(exerciseId);
      if (idNum != null) {
        final q = await FirebaseFirestore.instance
            .collection('exercises')
            .where('id', isEqualTo: idNum)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) data = q.docs.first.data();
      }
    }

    if (data != null) {
      final video =
          data['urlVideo']?.toString() ?? data['videoUrl']?.toString();
      final titulo = data['nombre']?.toString();
      return <String, String?>{'video': video, 'titulo': titulo};
    }
  } catch (_) {}

  return <String, String?>{'video': null, 'titulo': null};
});
