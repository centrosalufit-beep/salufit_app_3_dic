import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminEditTimeRecordsScreen extends StatefulWidget {
  const AdminEditTimeRecordsScreen({super.key});
  @override
  State<AdminEditTimeRecordsScreen> createState() => _AdminEditTimeRecordsScreenState();
}

class _AdminEditTimeRecordsScreenState extends State<AdminEditTimeRecordsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          ColoredBox(
            color: Colors.white.withValues(alpha: 0.8),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timeClockRecords')
                  .where('timestamp', isGreaterThanOrEqualTo: start)
                  .where('timestamp', isLessThanOrEqualTo: end)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No hay registros para este día.', style: TextStyle(color: Colors.white)));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data()! as Map<String, dynamic>;
                    final fechaRegistro = data.safeDateTime('timestamp');
                    return Card(
                      color: Colors.white.withValues(alpha: 0.8),
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        title: Text('Usuario: ${data.safeString('userId')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Tipo: ${data.safeString('type')} | Hora: ${DateFormat('HH:mm').format(fechaRegistro)}'),
                        trailing: const Icon(Icons.edit, color: Colors.orange),
                        onTap: () {},
                      ),
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
}
