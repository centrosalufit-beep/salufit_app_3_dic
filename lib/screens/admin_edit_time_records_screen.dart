import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminEditTimeRecordsScreen extends StatefulWidget {
  const AdminEditTimeRecordsScreen({super.key});

  @override
  State<AdminEditTimeRecordsScreen> createState() => _AdminEditTimeRecordsScreenState();
}

class _AdminEditTimeRecordsScreenState extends State<AdminEditTimeRecordsScreen> {
  DateTime _selectedDate = DateTime.now();
  
  List<Map<String, String>> _staffList = []; 
  Map<String, String> _staffEmails = {}; 

  @override
  void initState() {
    super.initState();
    _cargarStaff();
  }

  String removeDiacritics(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  Future<void> _cargarStaff() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      
      final List<Map<String, String>> tempStaff = [];
      final Map<String, String> tempEmails = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String rol = (data['rol'] ?? 'cliente').toString().toLowerCase().trim();
        
        if (rol == 'admin' || rol == 'administrador' || rol == 'profesional') {
          final String nombre = data['nombreCompleto'] ?? data['nombre'] ?? 'Sin Nombre';
          tempStaff.add({
            'id': doc.id,
            'label': '$nombre (${doc.id})', 
          });
          if (data['email'] != null) {
            tempEmails[doc.id] = data['email'];
          }
        }
      }

      tempStaff.sort((a, b) {
        final String nombreA = removeDiacritics(a['label']!.toLowerCase());
        final String nombreB = removeDiacritics(b['label']!.toLowerCase());
        return nombreA.compareTo(nombreB);
      });

      if (mounted) {
        setState(() {
          _staffList = tempStaff;
          _staffEmails = tempEmails;
        });
      }
    } catch (e) {
      debugPrint('Error cargando staff: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _editarRegistro(String docId, Map<String, dynamic> data, String nombreUsuario) {
    final timeController = TextEditingController(
      text: DateFormat('HH:mm').format((data['timestamp'] as Timestamp).toDate())
    );
    String tipoSeleccionado = data['type']; 

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Corregir Fichaje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Empleado: $nombreUsuario', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: tipoSeleccionado,
              items: const [
                DropdownMenuItem(value: 'IN', child: Text('Entrada (IN)')),
                DropdownMenuItem(value: 'OUT', child: Text('Salida (OUT)')),
              ],
              onChanged: (val) => tipoSeleccionado = val!,
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: timeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Nueva Hora', 
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time)
              ),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: dialogContext, 
                  initialTime: TimeOfDay.fromDateTime((data['timestamp'] as Timestamp).toDate())
                );
                if (time != null) {
                  timeController.text = "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Confirmación de borrado
              final bool? confirm = await showDialog(
                context: dialogContext, 
                builder: (c) => AlertDialog(
                  title: const Text('¿Eliminar?'), 
                  actions: [TextButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('SÍ'))]
                )
              );
              
              if (confirm == true) {
                await FirebaseFirestore.instance.collection('timeClockRecords').doc(docId).delete();
                
                // Verificamos si el widget principal sigue montado antes de usar lógica de UI
                if (!mounted) return; 
                
                // Cerramos el diálogo usando su propio contexto si sigue válido
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                
                // Usamos el contexto global (this.context) que está protegido por !mounted
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
              }
            }, 
            child: const Text('Borrar', style: TextStyle(color: Colors.red))
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final List<String> parts = timeController.text.split(':');
                final DateTime nuevaFechaHora = DateTime(
                  _selectedDate.year, _selectedDate.month, _selectedDate.day,
                  int.parse(parts[0]), int.parse(parts[1])
                );

                await FirebaseFirestore.instance.collection('timeClockRecords').doc(docId).update({
                  'timestamp': Timestamp.fromDate(nuevaFechaHora),
                  'type': tipoSeleccionado,
                  'isManualEntry': true, 
                  'manualReason': 'Corrección Admin' 
                });

                if (!mounted) return;

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Corregido correctamente'), backgroundColor: Colors.green));
                
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar Cambios')
          ),
        ],
      ),
    );
  }

  void _crearFichajeManual() {
    final timeController = TextEditingController(text: '09:00');
    String tipo = 'IN';
    String? selectedUserId; 

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Añadir Fichaje Manual'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Añade un fichaje que no se registró.'),
                  const SizedBox(height: 15),
                  
                  if (_staffList.isEmpty)
                    const Text('Cargando lista de profesionales...', style: TextStyle(color: Colors.grey))
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Profesional', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person)
                      ),
                      initialValue: selectedUserId,
                      items: _staffList.map((staff) {
                        return DropdownMenuItem(
                          value: staff['id'],
                          child: Text(staff['label']!, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedUserId = val;
                        });
                      },
                    ),

                  const SizedBox(height: 10),
                  
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    items: const [
                      DropdownMenuItem(value: 'IN', child: Text('Entrada (IN)')),
                      DropdownMenuItem(value: 'OUT', child: Text('Salida (OUT)')),
                    ],
                    onChanged: (val) => setStateDialog(() => tipo = val!),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(context: dialogContext, initialTime: const TimeOfDay(hour: 9, minute: 0));
                      if (time != null) {
                        timeController.text = "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUserId == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Selecciona un profesional')));
                      return;
                    }
                    try {
                      final List<String> parts = timeController.text.split(':');
                      final DateTime fechaHora = DateTime(
                        _selectedDate.year, _selectedDate.month, _selectedDate.day,
                        int.parse(parts[0]), int.parse(parts[1])
                      );
                      
                      final String? userEmail = _staffEmails[selectedUserId];

                      await FirebaseFirestore.instance.collection('timeClockRecords').add({
                        'userId': selectedUserId, 
                        'userEmail': userEmail, 
                        'timestamp': Timestamp.fromDate(fechaHora),
                        'type': tipo,
                        'deviceId': 'manual_admin',
                        'isManualEntry': true,
                        'manualReason': 'Añadido por Admin'
                      });

                      if (!mounted) return; 

                      // Verificación segura del contexto del diálogo
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext); 
                      }
                      
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Fichaje creado'), backgroundColor: Colors.green));
                      
                    } catch (e) {
                       if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Crear')
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    final DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(title: const Text('Corregir Fichajes'), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _crearFichajeManual,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                const Text('Viendo día: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, color: Colors.orange),
                  label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, color: Colors.black)),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('timeClockRecords')
                  .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
                  .where('timestamp', isLessThanOrEqualTo: endOfDay)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No hay fichajes este día'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final DateTime dt = (data['timestamp'] as Timestamp).toDate();
                    final String userId = data['userId'];
                    final String type = data['type'];
                    final bool manual = data['isManualEntry'] ?? false;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnap) {
                        String nombre = 'ID: $userId';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final uData = userSnap.data!.data() as Map<String, dynamic>;
                          nombre = uData['nombreCompleto'] ?? uData['nombre'] ?? nombre;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: ListTile(
                            leading: Icon(
                              type == 'IN' ? Icons.login : Icons.logout, 
                              color: type == 'IN' ? Colors.green : Colors.red
                            ),
                            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              "${DateFormat('HH:mm').format(dt)} ${manual ? '(Manual)' : ''}",
                              style: TextStyle(color: manual ? Colors.orange : Colors.grey)
                            ),
                            trailing: const Icon(Icons.edit, color: Colors.grey),
                            onTap: () => _editarRegistro(docs[index].id, data, nombre),
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
    );
  }
}