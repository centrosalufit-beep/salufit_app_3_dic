import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminRenewalScreen extends StatefulWidget {
  const AdminRenewalScreen({super.key});
  @override
  State<AdminRenewalScreen> createState() => _AdminRenewalScreenState();
}

class _AdminRenewalScreenState extends State<AdminRenewalScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final TextEditingController _tokensController = TextEditingController(text: '9');
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUsers = <String>{};
  bool _isProcessing = false;
  String _query = '';

  Future<void> _renovarSeleccionados() async {
    if (_selectedUsers.isEmpty) return;
    final tokensNum = int.tryParse(_tokensController.text) ?? 9;
    setState(() => _isProcessing = true);
    try {
      final db = FirebaseFirestore.instance;
      var batch = db.batch();
      var count = 0;

      for (final uid in _selectedUsers) {
        final ref = db.collection('passes').doc();
        batch.set(ref, {
          'userId': uid,
          'tokensRestantes': tokensNum,
          'tokensIniciales': tokensNum,
          'mes': _selectedMonth,
          'anio': _selectedYear,
          'activo': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
        count++;
        if (count % 450 == 0) {
          await batch.commit();
          batch = db.batch();
        }
      }
      if (count % 450 != 0) {
        await batch.commit();
      }

      debugPrint('>>> [BONOS] Creados $count bonos de $tokensNum tokens para $_selectedMonth/$_selectedYear');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count bonos de $tokensNum tokens creados'), backgroundColor: Colors.green),
        );
        setState(_selectedUsers.clear);
      }
    } catch (e) {
      debugPrint('>>> [BONOS] ERROR: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error en la operacion'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tokensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Gestion de Bonos Mensuales'), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          if (_isProcessing) const LinearProgressIndicator(color: Colors.orange),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedMonth,
                        decoration: const InputDecoration(labelText: 'Mes', border: OutlineInputBorder()),
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM', 'es').format(DateTime(2024, i + 1)).toUpperCase()))),
                        onChanged: (v) => setState(() => _selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        decoration: const InputDecoration(labelText: 'Ano', border: OutlineInputBorder()),
                        items: [DateTime.now().year, DateTime.now().year + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _tokensController,
                        decoration: const InputDecoration(labelText: 'Tokens', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Buscar paciente...', prefixIcon: Icon(Icons.person_search), border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ],
            ),
          ),

          // LISTA DE PACIENTES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users_app')
                  .where('rol', isEqualTo: 'cliente')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay pacientes registrados', style: TextStyle(color: Colors.black54, fontSize: 14)));
                }

                var docs = snapshot.data!.docs;
                if (_query.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    final nombre = data.safeString('nombreCompleto').toLowerCase();
                    final email = data.safeString('email').toLowerCase();
                    final historia = data.safeString('numHistoria').toLowerCase();
                    return nombre.contains(_query) || email.contains(_query) || historia.contains(_query);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data()! as Map<String, dynamic>;
                    final uid = doc.id;
                    final nombre = data.safeString('nombreCompleto');
                    final email = data.safeString('email');
                    final historia = data.safeString('numHistoria');
                    final isSelected = _selectedUsers.contains(uid);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF009688).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: const Color(0xFF009688), width: 2) : null,
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v!) {
                              _selectedUsers.add(uid);
                            } else {
                              _selectedUsers.remove(uid);
                            }
                          });
                        },
                        activeColor: const Color(0xFF009688),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('H: $historia | $email', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        secondary: CircleAvatar(
                          backgroundColor: const Color(0xFF009688),
                          radius: 18,
                          child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // BOTON RENOVAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _selectedUsers.isEmpty || _isProcessing ? null : _renovarSeleccionados,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.autorenew),
              label: Text('RENOVAR SELECCIONADOS (${_selectedUsers.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
