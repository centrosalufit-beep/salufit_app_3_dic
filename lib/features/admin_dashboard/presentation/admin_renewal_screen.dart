import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminRenewalScreen extends StatefulWidget {
  const AdminRenewalScreen({super.key});

  @override
  State<AdminRenewalScreen> createState() => _AdminRenewalScreenState();
}

class _AdminRenewalScreenState extends State<AdminRenewalScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _query = '';
  final TextEditingController _tokensController = TextEditingController(text: '9');
  final Set<String> _selectedUsers = <String>{};
  bool _isProcessing = false;

  Future<void> _renovarSeleccionados() async {
    if (_selectedUsers.isEmpty) return;
    
    final tokensNum = int.tryParse(_tokensController.text) ?? 9;
    setState(() => _isProcessing = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final authToken = await user?.getIdToken();

      final List<Map<String, dynamic>> listaPayload = _selectedUsers.map((uid) => {
        'userId': uid,
        'tokens': tokensNum,
      },).toList();

      final response = await http.post(
        Uri.parse(AppConfig.urlRenovarBonos),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(<String, dynamic>{
          'listaUsuarios': listaPayload,
          'mes': _selectedMonth,
          'anio': _selectedYear,
          'tokensPorDefecto': tokensNum,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Renovación masiva completada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        setState(_selectedUsers.clear);
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = <int>[DateTime.now().year, DateTime.now().year + 1];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Gestión de Bonos (Real-Time)'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_isProcessing) const LinearProgressIndicator(color: Colors.orange),
          
          // --- PANEL DE CONFIGURACIÓN SUPERIOR ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Mes',
                          border: OutlineInputBorder(),
                        ),
                        items: List<DropdownMenuItem<int>>.generate(
                          12,
                          (int i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text(
                              DateFormat('MMMM', 'es')
                                  .format(DateTime(2024, i + 1))
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ).toList(),
                        onChanged: (int? v) => setState(() => _selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          border: OutlineInputBorder(),
                        ),
                        items: years.map((int y) => DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y'),
                        ),).toList(),
                        onChanged: (int? v) => setState(() => _selectedYear = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _tokensController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tokens',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre (solo App activa)...',
                    prefixIcon: Icon(Icons.person_search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                  ),
                  onChanged: (String v) => setState(() => _query = v.toLowerCase()),
                ),
              ],
            ),
          ),

          // --- LISTADO DE PACIENTES CON SALDO REAL ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('rol', isEqualTo: 'cliente')
                  .where('termsAccepted', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  if (data.containsKey('migradoA')) return false;
                  final nombre = data.safeString('nombreCompleto').toLowerCase();
                  return _query.isEmpty || nombre.contains(_query);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No hay clientes activos para esta búsqueda.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = docs[index];
                    final userData = userDoc.data()! as Map<String, dynamic>;
                    final uid = userDoc.id;

                    return StreamBuilder<QuerySnapshot>(
                      // SINCRONIZACIÓN: Leer saldo de la colección 'passes' real
                      stream: FirebaseFirestore.instance
                          .collection('passes')
                          .where('userId', isEqualTo: uid)
                          .where('activo', isEqualTo: true)
                          .snapshots(),
                      builder: (context, passSnap) {
                        var saldoReal = 0;
                        if (passSnap.hasData && passSnap.data!.docs.isNotEmpty) {
                          final pData = passSnap.data!.docs.first.data()! as Map<String, dynamic>;
                          saldoReal = (pData['tokensRestantes'] as num?)?.toInt() ?? 0;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: CheckboxListTile(
                            secondary: CircleAvatar(
                              backgroundColor: Colors.teal.shade50,
                              child: const Icon(Icons.person, color: Color(0xFF00796B)),
                            ),
                            title: Text(
                              userData.safeString('nombreCompleto'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userData.safeString('email'), style: const TextStyle(fontSize: 11)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'SALDO EN APP: $saldoReal sesiones',
                                    style: const TextStyle(
                                      color: Color(0xFF00796B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            value: _selectedUsers.contains(uid),
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected ?? false) {
                                  _selectedUsers.add(uid);
                                } else {
                                  _selectedUsers.remove(uid);
                                }
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: ElevatedButton(
          onPressed: (_selectedUsers.isEmpty || _isProcessing) ? null : _renovarSeleccionados,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00796B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            'RENOVAR SELECCIONADOS (${_selectedUsers.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
