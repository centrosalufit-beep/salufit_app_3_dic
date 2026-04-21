import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_documents_screen.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_profile_screen.dart';

import 'overflow_test_harness.dart';

Future<FakeFirebaseFirestore> _buildFirestore() async {
  final db = FakeFirebaseFirestore();
  const uid = 'test-client-uid';
  await db.collection('users_app').doc(uid).set({
    'uid': uid,
    'email': 'cliente@test.com',
    'nombre': 'Cliente',
    'nombreCompleto': 'Cliente Test Completo',
    'rol': 'cliente',
    'activo': true,
    'termsAccepted': true,
    'passwordUpdated': true,
    'dateOfBirthSet': true,
    'consentVersion': '2026.2',
    'numHistoria': '000622',
  });
  // Datos para que los StreamBuilder no estén vacíos
  await db.collection('passes').add({
    'userId': uid,
    'activo': true,
    'tokensRestantes': 5,
    'tokensTotales': 8,
    'mes': DateTime.now().month,
    'anio': DateTime.now().year,
  });
  await db.collection('bookings').add({
    'userId': uid,
    'groupClassId': 'class-1',
    'estado': 'confirmado',
    'fechaReserva': Timestamp.now(),
  });
  await db.collection('groupClasses').doc('class-1').set({
    'nombre': 'Yoga',
    'monitor': 'Ana',
    'fechaHoraInicio': Timestamp.now(),
    'aforoActual': 5,
    'aforoMax': 12,
  });
  await db.collection('patient_metrics').add({
    'userId': uid,
    'nombre': 'Peso',
    'valor': 75.0,
    'unidad': 'kg',
    'fecha': Timestamp.now(),
    'categoria': 'nutricion',
  });
  await db.collection('documents').add({
    'userId': uid,
    'titulo': 'Consentimiento Yoga',
    'firmado': true,
    'fechaFirma': Timestamp.now(),
  });
  return db;
}

MockFirebaseAuth _buildAuth() => MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'test-client-uid',
        email: 'cliente@test.com',
        displayName: 'Cliente Test',
      ),
    );

void main() {
  group('CLIENTE — overflow en todos los dispositivos', () {
    testWidgets('ClientProfileScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ClientProfileScreen(userId: 'test-client-uid'),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('ClientProfileScreen', results);
      assertNoOverflow(results, 'ClientProfileScreen');
    });

    testWidgets('ClientDocumentsScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ClientDocumentsScreen(userId: 'test-client-uid'),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('ClientDocumentsScreen', results);
      assertNoOverflow(results, 'ClientDocumentsScreen');
    });

    testWidgets('ClientClassListScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ClientClassListScreen(
            userId: 'test-client-uid',
            userRole: 'cliente',
          ),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('ClientClassListScreen', results);
      assertNoOverflow(results, 'ClientClassListScreen');
    });
  });
}
