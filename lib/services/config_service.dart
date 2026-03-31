import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  factory ConfigService() => _instance;
  ConfigService._internal();
  static final ConfigService _instance = ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene la configuración de facturación y exclusiones en tiempo real.
  /// Se conecta a: system_config/billing_params
  Stream<Map<String, dynamic>> getBillingConfig() {
    return _firestore
        .collection('system_config')
        .doc('billing_params')
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Valores por defecto de seguridad si no existe el documento
        return <String, Object>{
          'standardRate': 55.0, // Tarifa base histórica
          'excludedKeywords': <String>[
            'maria',
            'dra. maría',
            'dra. maria',
            'javi',
            'javier',
            'carla',
            'estela',
          ],
        };
      }
      return snapshot.data()!;
    })
        // CORRECCIÓN: Tipado explícito del error (Object e)
        .handleError((Object e) {
      if (kDebugMode) {
        debugPrint('Error obteniendo config de facturacion');
      }
      return <String, dynamic>{};
    });
  }

  /// Método para inicializar la configuración por defecto si no existe (Solo Admin)
  Future<void> initializeDefaultConfig() async {
    final docRef = _firestore.collection('system_config').doc('billing_params');
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set(<String, dynamic>{
        'standardRate': 55.0,
        'excludedKeywords': <String>[
          'maria',
          'dra. maría',
          'javi',
          'javier',
          'carla',
          'estela',
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
}
