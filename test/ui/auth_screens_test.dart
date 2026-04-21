import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salufit_app/features/auth/presentation/activation_screen.dart';
import 'package:salufit_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:salufit_app/features/auth/presentation/login_screen.dart';
import 'package:salufit_app/features/auth/presentation/migration/date_of_birth_dialog.dart';
import 'package:salufit_app/features/auth/presentation/migration/granular_consent_dialog.dart';
import 'package:salufit_app/features/auth/presentation/migration/password_migration_dialog.dart';
import 'package:salufit_app/features/auth/presentation/terms_acceptance_screen.dart';

import 'overflow_test_harness.dart';

Future<FakeFirebaseFirestore> _buildFirestore() async {
  final db = FakeFirebaseFirestore();
  await db.collection('users_app').doc('test-uid').set({
    'uid': 'test-uid',
    'email': 'test@test.com',
    'nombre': 'Test User',
    'nombreCompleto': 'Test User Full',
    'rol': 'cliente',
    'activo': true,
    'termsAccepted': true,
    'passwordUpdated': true,
    'dateOfBirthSet': true,
    'consentVersion': '2026.2',
  });
  return db;
}

MockFirebaseAuth _buildAuth() => MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'test-uid',
        email: 'test@test.com',
        displayName: 'Test User',
      ),
    );

void main() {
  group('AUTH — overflow en todos los dispositivos', () {
    testWidgets('LoginScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const LoginScreen(),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('LoginScreen', results);
      assertNoOverflow(results, 'LoginScreen');
    });

    testWidgets('ActivationScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ActivationScreen(),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('ActivationScreen', results);
      assertNoOverflow(results, 'ActivationScreen');
    });

    testWidgets('ForgotPasswordScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const ForgotPasswordScreen(),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('ForgotPasswordScreen', results);
      assertNoOverflow(results, 'ForgotPasswordScreen');
    });

    testWidgets('TermsAcceptanceScreen', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const TermsAcceptanceScreen(),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('TermsAcceptanceScreen', results);
      assertNoOverflow(results, 'TermsAcceptanceScreen');
    });

    testWidgets('PasswordMigrationDialog', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const PasswordMigrationDialog(),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('PasswordMigrationDialog', results);
      assertNoOverflow(results, 'PasswordMigrationDialog');
    });

    testWidgets('DateOfBirthDialog', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const DateOfBirthDialog(),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('DateOfBirthDialog', results);
      assertNoOverflow(results, 'DateOfBirthDialog');
    });

    testWidgets('GranularConsentDialog', (tester) async {
      final db = await _buildFirestore();
      final auth = _buildAuth();
      final results = await runAcrossDevices(
        tester: tester,
        buildWidget: () => wrapInAppWithMocks(
          const GranularConsentDialog(),
          firestore: db,
          auth: auth,
        ),
        devices: DeviceSize.allForMobileScreens,
      );
      printReport('GranularConsentDialog', results);
      assertNoOverflow(results, 'GranularConsentDialog');
    });
  });
}
