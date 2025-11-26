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
  bool _isLoading = false;
  
  // Lista para el desplegable de profesionales
  List<Map<String, String>> _staffList = []; 

  @override
  void initState() {
    super.initState();
    _cargarStaff();
  }

  // Función auxiliar para limpiar acentos (clave para ordenar bien "Álvaro")
  String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  // --- CARGAR SOLO ADMINS Y PROFESIONALES (ORDENADOS) ---
  Future<void> _cargarStaff() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('users').get();
      
      List<Map<String, String>> tempStaff = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data();
        String rol = (data['rol'] ?? 'cliente').toString().toLowerCase().trim();
        
        // Filtramos: Solo queremos Staff
        if (rol == 'admin' || rol == 'administrador' || rol == 'profesional') {
          String nombre = data['nombreCompleto'] ?? data['nombre'] ?? 'Sin Nombre';
          tempStaff.add({
            'id': doc.id,
            'label': '$nombre (${doc.id})', // Ej: "Silvio Marin (000001)"
          });
        }
      }

      // ORDENACIÓN ALFABÉTICA ROBUSTA (Ignora acentos y mayúsculas)
      tempStaff.sort((a, b) {
        String nombreA = removeDiacritics(a['label']!.toLowerCase());
        String nombreB = removeDiacritics(b['label']!.toLowerCase());
        return nombreA.compareTo(nombreB);
      });

      if (mounted) {
        setState(() {
          _staffList = tempStaff;
        });
      }
    } catch (e) {
      print("Error cargando staff: $e");
    }
  }

  // Función para seleccionar fecha
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

  // Función para editar un registro concreto
  void _editarRegistro(String docId, Map<String, dynamic> data, String nombreUsuario) {
    final _timeController = TextEditingController(
      text: DateFormat('HH:mm').format((data['timestamp'] as Timestamp).toDate())
    );
    String tipoSeleccionado = data['type']; // 'IN' o 'OUT'

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Corregir Fichaje"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Empleado: $nombreUsuario", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: tipoSeleccionado,
              items: const [
                DropdownMenuItem(value: 'IN', child: Text("Entrada (IN)")),
                DropdownMenuItem(value: 'OUT', child: Text("Salida (OUT)")),
              ],
              onChanged: (val) => tipoSeleccionado = val!,
              decoration: const InputDecoration(labelText: "Tipo", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Nueva Hora", 
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time)
              ),
              onTap: () async {
                TimeOfDay? time = await showTimePicker(
                  context: context, 
                  initialTime: TimeOfDay.fromDateTime((data['timestamp'] as Timestamp).toDate())
                );
                if (time != null) {
                  _timeController.text = "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // BORRAR REGISTRO
              bool? confirm = await showDialog(context: context, builder: (c) => AlertDialog(title: const Text("¿Eliminar?"), actions: [TextButton(onPressed: ()=>Navigator.pop(c,true), child: const Text("SÍ"))]));
              if (confirm == true) {
                await FirebaseFirestore.instance.collection('timeClockRecords').doc(docId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registro eliminado")));
                }
              }
            }, 
            child: const Text("Borrar", style: TextStyle(color: Colors.red))
          ),
          ElevatedButton(
            onPressed: () async {
              // GUARDAR CAMBIOS
              try {
                List<String> parts = _timeController.text.split(':');
                DateTime nuevaFechaHora = DateTime(
                  _selectedDate.year, _selectedDate.month, _selectedDate.day,
                  int.parse(parts[0]), int.parse(parts[1])
                );

                await FirebaseFirestore.instance.collection('timeClockRecords').doc(docId).update({
                  'timestamp': Timestamp.fromDate(nuevaFechaHora),
                  'type': tipoSeleccionado,
                  'isManualEntry': true, 
                  'manualReason': 'Corrección Admin' 
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Corregido correctamente"), backgroundColor: Colors.green));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Guardar Cambios")
          ),
        ],
      ),
    );
  }

  // --- FUNCIÓN MEJORADA: CON DESPLEGABLE DE STAFF ---
  void _crearFichajeManual() {
    final _timeController = TextEditingController(text: "09:00");
    String tipo = 'IN';
    String? selectedUserId; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Añadir Fichaje Manual"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Añade un fichaje que no se registró."),
                  const SizedBox(height: 15),
                  
                  // DESPLEGABLE DE PROFESIONALES (Ya ordenado en _cargarStaff)
                  if (_staffList.isEmpty)
                    const Text("Cargando lista de profesionales...", style: TextStyle(color: Colors.grey))
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Seleccionar Profesional", 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person)
                      ),
                      value: selectedUserId,
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
                    value: tipo,
                    items: const [
                      DropdownMenuItem(value: 'IN', child: Text("Entrada (IN)")),
                      DropdownMenuItem(value: 'OUT', child: Text("Salida (OUT)")),
                    ],
                    onChanged: (val) => setStateDialog(() => tipo = val!),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Hora", border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                    onTap: () async {
                      TimeOfDay? time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                      if (time != null) {
                        _timeController.text = "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona un profesional")));
                      return;
                    }
                    try {
                      List<String> parts = _timeController.text.split(':');
                      DateTime fechaHora = DateTime(
                        _selectedDate.year, _selectedDate.month, _selectedDate.day,
                        int.parse(parts[0]), int.parse(parts[1])
                      );

                      await FirebaseFirestore.instance.collection('timeClockRecords').add({
                        'userId': selectedUserId, 
                        'timestamp': Timestamp.fromDate(fechaHora),
                        'type': tipo,
                        'deviceId': 'manual_admin',
                        'isManualEntry': true,
                        'manualReason': 'Añadido por Admin'
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fichaje creado"), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Crear")
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
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(title: const Text("Corregir Fichajes"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: _crearFichajeManual,
      ),
      body: Column(
        children: [
          // SELECTOR DE FECHA
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                const Text("Viendo día: ", style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, color: Colors.orange),
                  label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16, color: Colors.black)),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),

          // LISTA DE FICHAJES DEL DÍA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('timeClockRecords')
                  .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
                  .where('timestamp', isLessThanOrEqualTo: endOfDay)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No hay fichajes este día"));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    DateTime dt = (data['timestamp'] as Timestamp).toDate();
                    String userId = data['userId'];
                    String type = data['type'];
                    bool manual = data['isManualEntry'] ?? false;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnap) {
                        String nombre = "ID: $userId";
                        if (userSnap.hasData && userSnap.data!.exists) {
                          var uData = userSnap.data!.data() as Map<String, dynamic>;
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