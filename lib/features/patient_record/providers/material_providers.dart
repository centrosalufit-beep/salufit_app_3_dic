import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('exercise_assignments')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
}

@riverpod
Future<Map<String, dynamic>?> exerciseDetails(Ref ref, String? id) async {
  if (id == null) return null;
  final doc = await FirebaseFirestore.instance.collection('exercises').doc(id).get();
  return doc.data();
}
