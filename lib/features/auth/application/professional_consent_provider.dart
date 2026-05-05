import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/auth/data/professional_consent_text.dart';

/// Estado del consentimiento profesional para el usuario actual.
/// - `null` → cargando.
/// - `false` → necesita firmar (no existe doc o versión obsoleta).
/// - `true` → firmado y vigente.
final professionalConsentSignedProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(false);
  }
  return db
      .collection('professional_consents')
      .doc(user.uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return false;
    final data = snap.data() ?? <String, dynamic>{};
    final firmadaVersion = data['version'] as String?;
    return firmadaVersion == kProfessionalConsentVersion;
  });
});
