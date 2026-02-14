import 'package:cloud_firestore/cloud_firestore.dart';

class ClassGeneratorService {
  static Future<void> generateMonth({
    required int month,
    required int year,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final start = DateTime(year, month);
    final end = DateTime(year, month + 1, 0);

    for (var date = start;
        date.isBefore(end.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      final day = date.weekday;

      if (day == DateTime.monday) {
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 7, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 8, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 9, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 11, 0);
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          17,
          0,
        );
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          18,
          0,
        );
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 19, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 20, 0);
      } else if (day == DateTime.tuesday) {
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          7,
          0,
        );
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          8,
          0,
        );
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          9,
          0,
        );
        _addClass(batch, firestore, 'Meditación', 'Ignacio', date, 10, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 16, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 17, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 18, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 19, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 20, 30);
      } else if (day == DateTime.wednesday) {
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 7, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 8, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 9, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 11, 0);
        _addClass(batch, firestore, 'Meditación', 'Ignacio', date, 16, 0);
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          17,
          0,
        );
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          18,
          0,
        );
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 19, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 20, 0);
      } else if (day == DateTime.thursday) {
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          7,
          0,
        );
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          8,
          0,
        );
        _addClass(
          batch,
          firestore,
          'Ejercicio Terapéutico',
          'Álvaro, Ibtissam y David',
          date,
          9,
          0,
        );
        _addClass(batch, firestore, 'Meditación', 'Ignacio', date, 10, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 16, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 17, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 18, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 19, 30);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 20, 30);
      } else if (day == DateTime.friday) {
        _addClass(batch, firestore, 'Meditación', 'Ignacio', date, 18, 0);
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 19, 0);
      } else if (day == DateTime.saturday) {
        _addClass(batch, firestore, 'Entrenamiento', 'Silvio', date, 10, 0);
      }
    }

    final configRef =
        firestore.collection('system_config').doc('clases_generadas');
    batch.set(
      configRef,
      {
        'ultimoMesGenerado': '$year-$month',
        'fechaUltimaGeneracion': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static void _addClass(
    WriteBatch batch,
    FirebaseFirestore firestore,
    String nombre,
    String monitor,
    DateTime date,
    int hora,
    int minuto,
  ) {
    final docRef = firestore.collection('groupClasses').doc();
    batch.set(docRef, {
      'nombre': nombre,
      'monitor': monitor,
      'fechaHoraInicio': Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, hora, minuto),
      ),
      'aforoMaximo': 12,
      'aforoActual': 0,
      'estado': 'activa',
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }
}
