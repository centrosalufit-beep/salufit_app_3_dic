import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'material_providers.g.dart';

@riverpod
class DailyProgress extends _$DailyProgress {
  @override
  List<String> build() => [];
  
  void markAsDone(String id) {
    if (!state.contains(id)) state = [...state, id];
  }
}

@riverpod
class MyAssignments extends _$MyAssignments {
  @override
  Stream<List<Map<String, dynamic>>> build() {
    // Por ahora vacío, se conectará a Firebase en la unificación con Surface
    return Stream.value([]);
  }
}

@riverpod
Future<Map<String, dynamic>?> exerciseDetails(Ref ref, String? id) async {
  if (id == null) return null;
  final doc = await FirebaseFirestore.instance.collection('exercises').doc(id).get();
  return doc.data();
}
