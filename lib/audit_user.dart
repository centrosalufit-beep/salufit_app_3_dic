import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    const targetEmail = 'cebegar@gmail.com';
    final firestore = FirebaseFirestore.instance;
    
    print('\n--- 🔍 INICIANDO AUDITORÍA PROFESIONAL: $targetEmail ---\n');

    // Intentamos buscar en la colección de usuarios
    final userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: targetEmail)
        .get();

    if (userQuery.docs.isNotEmpty) {
      print('✅ ESTADO: USUARIO ACTIVO ENCONTRADO');
      print('   👉 CONCLUSIÓN: El cliente debe usar "RECORDAR CONTRASEÑA".');
    } else {
      print('⚠️ No está en usuarios activos. Buscando en legacy...');
      final legacyQuery = await firestore
          .collection('legacy_import')
          .where('email', isEqualTo: targetEmail)
          .get();

      if (legacyQuery.docs.isNotEmpty) {
        print('📥 ESTADO: CLIENTE ANTIGUO DETECTADO');
        print('   👉 CONCLUSIÓN: El cliente debe usar "PRIMERA VEZ".');
      } else {
        print('❌ ESTADO: CORREO NO ENCONTRADO EN NINGUNA BASE DE DATOS.');
      }
    }
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      print('\n🚫 ERROR DE SEGURIDAD: Firestore ha bloqueado la lectura.');
      print('💡 ACCIÓN: Ve a Firebase Console > Firestore > Rules y permite la lectura temporal:');
      print('   allow read: if true;');
      print('   (No olvides revertirlo después de la prueba)');
    } else {
      print('❌ Error de Firebase: ${e.message}');
    }
  } catch (e) {
    print('❌ Error inesperado: $e');
  }
  print('\n--- 🏁 FIN DE LA AUDITORÍA ---\n');
}
