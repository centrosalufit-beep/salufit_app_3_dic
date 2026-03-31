import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Generador de Keywords Inteligente 2026
  List<String> _generateKeywords(String nombre, String apellidos, String numHistoria) {
    final cleanH = numHistoria.trim();
    // Normalizamos a 6 dígitos como hace la App móvil
    final paddedH = cleanH.padLeft(6, '0');
    
    final words = '$nombre $apellidos $cleanH $paddedH'.toLowerCase().split(' ')
      ..add('$nombre $apellidos'.toLowerCase())
      ..add(cleanH.toLowerCase())
      ..add(paddedH.toLowerCase()); 
      
    return words.where((w) => w.isNotEmpty).toSet().toList();
  }

  Future<void> activateClient({
    required String email, 
    required String numHistoria, 
    required String password
  }) async {
    // Normalizamos la entrada (Inferencia automática de tipo String)
    final normalizedH = numHistoria.trim().padLeft(6, '0');
    
    final bbddDoc = await _db.collection('bbdd').doc(email.toLowerCase()).get();
    if (!bbddDoc.exists) throw Exception('No autorizado.');

    final data = bbddDoc.data()!;
    // Comparamos el número de la BBDD
    final dbH = (data['numHistoria'] as String? ?? '').trim().padLeft(6, '0');
    
    if (dbH != normalizedH) throw Exception('Nº Historia incorrecto.');

    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    final nombre = data['nombre'] as String? ?? '';        
    final nombreCompleto = data['nombreCompleto'] as String? ?? '';
    final apellidos = nombreCompleto.replaceFirst(nombre, '').trim();

    await _db.collection('users_app').doc(uid).set({       
      'uid': uid,
      'numHistoria': normalizedH,
      'email': email.toLowerCase(),
      'nombre': nombre,
      'apellidos': apellidos,
      'nombreCompleto': nombreCompleto,
      'activo': true,
      'rol': 'cliente',
      'termsAccepted': false,
      'keywords': _generateKeywords(nombre, apellidos, normalizedH),
      'createdAt': FieldValue.serverTimestamp(),
      'deviceInfo': 'App Mobile 2026',
    });

    await bbddDoc.reference.update({'status': 'activated', 'activatedUid': uid});
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);      
  }

  Future<void> signOut() => _auth.signOut();
}
