// test/features/bookings/domain/models/class_model_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salufit_app/features/bookings/domain/models/class_model.dart';

// ⚠️ ESTA ES LA FUNCIÓN QUE FALTABA
void main() {
  group('ClassModel Robustness Audit', () {
    // Caso 1: Datos perfectos (Happy Path)
    test('Debe parsear correctamente datos completos y válidos', () {
      final now = Timestamp.now();
      final data = {
        'nombre': 'Yoga Avanzado',
        'monitor': 'Elena',
        'fechaHoraInicio': now,
        'aforoMaximo': 15,
        'aforoActual': 5,
        'asistentes': ['user1', 'user2'],
      };

      // Usamos el factory .fromMap que creamos en el paso anterior
      final model = ClassModel.fromMap(data, 'class_123');

      expect(model.id, 'class_123');
      expect(model.name, 'Yoga Avanzado');
      expect(model.maxCapacity, 15);
      expect(model.attendees.length, 2);
    });

    // Caso 2: Defensa contra Nulos (Safety Check)
    test('Debe usar valores por defecto si faltan campos (null safety)', () {
      final data = <String, dynamic>{}; // Mapa vacío simula documento corrupto

      final model = ClassModel.fromMap(data, 'class_empty');

      expect(model.name, 'Clase sin nombre'); // Default definido
      expect(model.instructor, 'Salufit'); // Default definido
      expect(model.maxCapacity, 12); // Default definido
      expect(model.currentCapacity, 0);
      expect(model.attendees, isEmpty);
    });

    // Caso 3: Defensa contra Tipos Incorrectos (Type mismatch)
    test('Debe resistir tipos de datos incorrectos sin crashear', () {
      final data = {
        'nombre': 12345, // El backend envía un número en vez de String
        'aforoMaximo': 'veinte', // String en vez de int
        'asistentes': 'no es una lista', // String en vez de List
      };

      try {
        final model = ClassModel.fromMap(data, 'class_bad_types');

        // Verificamos que los valores sean seguros pese a la basura en la entrada
        expect(model.maxCapacity, 12); // Fallback por defecto
        expect(model.attendees, isEmpty); // Fallback por defecto
      } catch (e) {
        fail('El modelo colapsó con tipos de datos incorrectos: $e');
      }
    });
  });
}
