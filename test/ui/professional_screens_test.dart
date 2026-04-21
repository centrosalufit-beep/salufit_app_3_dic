import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salufit_app/features/professional/presentation/professional_dashboard_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_desktop_dashboard_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_tasks_screen.dart';

import 'overflow_test_harness.dart';

Future<FakeFirebaseFirestore> _buildFirestore() async {
  final db = FakeFirebaseFirestore();
  const uid = 'test-pro-uid';
  await db.collection('users_app').doc(uid).set({
    'uid': uid,
    'email': 'pro@test.com',
    'nombre': 'Profesional',
    'nombreCompleto': 'Profesional Test Completo',
    'rol': 'profesional',
    'activo': true,
    'termsAccepted': true,
  });
  await db.collection('timeClockRecords').add({
    'userId': uid,
    'userName': 'Profesional Test',
    'type': 'IN',
    'timestamp': Timestamp.now(),
  });
  await db.collection('staff_tasks').add({
    'asignadoAId': uid,
    'creadoPorNombre': 'Admin',
    'titulo': 'Revisar paciente',
    'descripcion': 'Descripcion corta',
    'estado': 'pendiente',
    'fechaLimite': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 3)),
    ),
    'fechaCreacion': Timestamp.now(),
  });
  await db.collection('crm_entries').add({
    'profesionalId': uid,
    'tipo': 'resena',
    'mes': DateTime.now().month,
    'anio': DateTime.now().year,
  });
  await db.collection('chats').add({
    'participants': [uid, 'other-uid'],
    'lastMessageTime': Timestamp.now(),
    'lastMessageSenderId': 'other-uid',
  });
  return db;
}

MockFirebaseAuth _buildAuth() => MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'test-pro-uid',
        email: 'pro@test.com',
        displayName: 'Profesional Test',
      ),
    );

void main() {
  group('PROFESSIONAL — overflow en todos los dispositivos', () {
    testWidgets('ProfessionalDashboardScreen (móvil)', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ProfessionalDashboardScreen(
            userId: 'test-pro-uid',
            userRole: 'profesional',
          ),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('ProfessionalDashboardScreen (móvil)', results);
      assertNoOverflow(results, 'ProfessionalDashboardScreen');
    });

    testWidgets('ProfessionalDesktopDashboardScreen (.exe)', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ProfessionalDesktopDashboardScreen(
            userId: 'test-pro-uid',
            userRole: 'profesional',
          ),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForDesktopScreens,
      );
      printReport('ProfessionalDesktopDashboardScreen', results);
      assertNoOverflow(results, 'ProfessionalDesktopDashboardScreen');
    });

    testWidgets('ProfessionalTasksScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ProfessionalTasksScreen(userId: 'test-pro-uid'),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('ProfessionalTasksScreen', results);
      assertNoOverflow(results, 'ProfessionalTasksScreen');
    });
  });
}
