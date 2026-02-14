import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Importamos la herramienta de seguridad para resolver el error de tipo DateTime
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminEditTimeRecordsScreen extends StatefulWidget {
  const AdminEditTimeRecordsScreen({super.key});
  @override
  State<AdminEditTimeRecordsScreen> createState() =>
      _AdminEditTimeRecordsScreenState();
}

class _AdminEditTimeRecordsScreenState
    extends State<AdminEditTimeRecordsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final start =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corregir Fichajes'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: <Widget>[
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2024),
            lastDate: DateTime.now(),
            onDateChanged: (DateTime d) => setState(() => _selectedDate = d),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timeClockRecords')
                  .where('timestamp', isGreaterThanOrEqualTo: start)
                  .where('timestamp', isLessThanOrEqualTo: end)
                  .snapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
              ) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int i) {
                    final doc = snapshot.data!.docs[i];
                    final data = doc.data()! as Map<String, dynamic>;

                    // CORRECCIÓN CRÍTICA: Uso de safeDateTime
                    // Resuelve el error: "argument type 'dynamic' can't be assigned to 'DateTime'"
                    final fechaRegistro = data.safeDateTime('timestamp');

                    return ListTile(
                      title: Text('Usuario: ${data.safeString('userId')}'),
                      subtitle: Text(
                        'Tipo: ${data.safeString('type')} | Hora: ${DateFormat('HH:mm').format(fechaRegistro)}',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _mostrarEditor(doc.id, data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarEditor(String id, Map<String, dynamic> data) {
    // Implementar diálogo para cambiar fecha/hora similar a fuente 435
  }
}
