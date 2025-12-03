import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminRenewalScreen extends StatefulWidget {
  const AdminRenewalScreen({super.key});

  @override
  State<AdminRenewalScreen> createState() => _AdminRenewalScreenState();
}

class _AdminRenewalScreenState extends State<AdminRenewalScreen> {
  final String _apiUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/renovarBonosBatch';
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  
  final TextEditingController _tokensController = TextEditingController(text: '8'); 

  String _searchQuery = ''; 
  Set<String> _selectedUserIds = {}; 
  bool _isLoading = false;
  bool _selectAll = false;
  bool _soloPendientes = true; 

  String removeDiacritics(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  Future<void> _ejecutarRenovacion() async {
    if (_selectedUserIds.isEmpty) return;

    final int? tokensInput = int.tryParse(_tokensController.text);
    if (tokensInput == null || tokensInput < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Introduce un número de tokens válido'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final List<Map<String, dynamic>> listaParaEnviar = _selectedUserIds.map((uid) {
        return {
          'userId': uid,
          'tokens': tokensInput, 
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'listaUsuarios': listaParaEnviar,
          'mes': _selectedMonth,
          'anio': _selectedYear,
          'tokensPorDefecto': tokensInput
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
          setState(() {
            _selectedUserIds.clear();
            _selectAll = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error desconocido'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Stream<QuerySnapshot> _getUsersStream() {
    final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
    
    if (_searchQuery.isEmpty) {
      return usersRef.orderBy('nombreCompleto').limit(100).snapshots();
    }

    final List<String> palabras = _searchQuery.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final String primeraPalabra = palabras.isNotEmpty ? palabras[0] : '';

    if (primeraPalabra.isEmpty) return usersRef.limit(100).snapshots();

    return usersRef
        .where('keywords', arrayContains: primeraPalabra) 
        .limit(100) 
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Renovaciones Mensuales'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4, 
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Mes',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedMonth,
                            isDense: true,
                            isExpanded: true,
                            items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(DateFormat('MMMM', 'es').format(DateTime(2024, index + 1)), overflow: TextOverflow.ellipsis))),
                            onChanged: (val) => setState(() => _selectedMonth = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedYear,
                            isDense: true,
                            isExpanded: true,
                            items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                            onChanged: (val) => setState(() => _selectedYear = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5), 
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _tokensController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'Tokens', 
                          border: OutlineInputBorder(), 
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14), 
                          isDense: true
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar (Ej: Jose Baydal...)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10)
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = removeDiacritics(val.trim().toLowerCase()));
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Ocultar los que ya tienen bono', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: _searchQuery.isNotEmpty 
                      ? const Text('(Desactivado temporalmente por búsqueda)', style: TextStyle(color: Colors.orange, fontSize: 12))
                      : null,
                  value: _soloPendientes,
                  activeThumbColor: Colors.teal,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _soloPendientes = val),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(), 
              builder: (context, snapshotUsers) {
                
                if (snapshotUsers.hasError) {
                   return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: SelectableText('Error: ${snapshotUsers.error}', style: const TextStyle(color: Colors.red))));
                }
                if (snapshotUsers.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('passes')
                      .where('mes', isEqualTo: _selectedMonth)
                      .where('anio', isEqualTo: _selectedYear)
                      .snapshots(),
                  builder: (context, snapshotPasses) {
                    if (!snapshotPasses.hasData) return const Center(child: CircularProgressIndicator());

                    final Set<String> usuariosConBono = {};
                    for (var doc in snapshotPasses.data!.docs) {
                      final String uid = doc['userId'].toString();
                      usuariosConBono.add(uid); 
                      usuariosConBono.add(uid.replaceFirst(RegExp(r'^0+'), ''));
                    }

                    final List<String> terminos = _searchQuery.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

                    final usuariosFiltrados = snapshotUsers.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      
                      final String nombreRaw = (data['nombreCompleto'] ?? data['nombre'] ?? '').toString();
                      final String nombreLimpio = removeDiacritics(nombreRaw.toLowerCase());
                      
                      final String id = doc.id.toLowerCase();
                      final String idSinCeros = doc.id.replaceFirst(RegExp(r'^0+'), '');
                      
                      bool coincide = true;
                      if (terminos.isNotEmpty) {
                        for (var termino in terminos) {
                          if (!nombreLimpio.contains(termino) && !id.contains(termino)) {
                            coincide = false;
                            break;
                          }
                        }
                      }
                      if (!coincide) return false;

                      final bool yaTieneBono = usuariosConBono.contains(doc.id) || usuariosConBono.contains(idSinCeros); 
                      
                      if (_searchQuery.isNotEmpty) {
                        return true; 
                      }

                      if (_soloPendientes && yaTieneBono) {
                        return false; 
                      }
                      
                      return true;
                    }).toList();

                    if (usuariosFiltrados.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('No se encontraron usuarios.'),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${usuariosFiltrados.length} Coincidencias', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              if (_searchQuery.isEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectAll = !_selectAll;
                                      if (_selectAll) {
                                        _selectedUserIds = usuariosFiltrados.map((u) => u.id).toSet();
                                      } else {
                                        _selectedUserIds.clear();
                                      }
                                    });
                                  },
                                  child: Text(_selectAll ? 'Deseleccionar todo' : 'Seleccionar todo'),
                                )
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: usuariosFiltrados.length,
                            itemBuilder: (context, index) {
                              final user = usuariosFiltrados[index];
                              final data = user.data() as Map<String, dynamic>;
                              final String nombre = data['nombreCompleto'] ?? data['nombre'] ?? 'Usuario';
                              
                              final bool isSelected = _selectedUserIds.contains(user.id);
                              final String idSinCeros = user.id.replaceFirst(RegExp(r'^0+'), '');
                              final bool yaPagado = usuariosConBono.contains(user.id) || usuariosConBono.contains(idSinCeros);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: Colors.teal,
                                title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Row(
                                  children: [
                                    Text('ID: ${user.id}'),
                                    if (yaPagado) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('PAGADO', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                      )
                                    ]
                                  ],
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: yaPagado ? Colors.green.shade100 : Colors.teal.shade100,
                                  child: Icon(yaPagado ? Icons.check : Icons.person, color: yaPagado ? Colors.green : Colors.teal),
                                ),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedUserIds.add(user.id);
                                    } else {
                                      _selectedUserIds.remove(user.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // CORRECCIÓN: Botón protegido por SafeArea
          if (_selectedUserIds.isNotEmpty)
            SafeArea(
              top: false, // Solo protegemos abajo
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _ejecutarRenovacion,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('ASIGNAR ${_tokensController.text} TOKENS A (${_selectedUserIds.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}