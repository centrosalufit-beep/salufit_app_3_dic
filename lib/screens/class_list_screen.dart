import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/group_class.dart';

class ClassListScreen extends StatefulWidget {
  final String userId;

  const ClassListScreen({super.key, required this.userId});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final String _crearReservaUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/crearReserva';
  final String _cancelarReservaUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/cancelarReserva';
  
  bool _isLoadingAction = false;
  DateTime _selectedDate = DateTime.now();

  final List<String> _adminIds = ['000001', '000622'];

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  MaterialColor _getColorPorClase(String nombreClase) {
    String nombre = nombreClase.toLowerCase(); 
    if (nombre.contains('entrenamiento')) return Colors.red; 
    if (nombre.contains('meditación') || nombre.contains('meditacion')) return Colors.blueGrey; 
    return Colors.blue; 
  }

  Future<void> _borrarClaseAdmin(String classId) async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Borrar Clase (Admin)"),
        content: const Text("Esta acción eliminará la clase permanentemente. ¿Seguro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance.collection('groupClasses').doc(classId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clase eliminada")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _reservarClase(String classId, String className) async {
    setState(() { _isLoadingAction = true; });
    try {
      final response = await http.post(
        Uri.parse(_crearReservaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'userId': widget.userId, 'groupClassId': classId }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reservada: $className'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isLoadingAction = false; });
    }
  }

  Future<void> _cancelarReserva(String bookingId, DateTime fechaClase) async {
    final DateTime ahora = DateTime.now();
    final int horasRestantes = fechaClase.difference(ahora).inHours;
    final bool esPenalizado = horasRestantes < 24;

    String titulo = esPenalizado ? "¡Atención! (Faltan ${horasRestantes}h)" : "Cancelar Reserva";
    String mensaje = esPenalizado
        ? "Quedan menos de 24h.\n\nSi cancelas, PERDERÁS EL TOKEN.\n\n¿Continuar?"
        : "Faltan más de 24h.\n\nEl token será devuelto a tu cuenta.";
    
    Color colorBtn = esPenalizado ? Colors.red : Colors.blue;

    bool? confirmar = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titulo, style: TextStyle(color: esPenalizado ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text("Sí, cancelar", style: TextStyle(color: colorBtn, fontWeight: FontWeight.bold))),
        ],
      )
    );
    
    if (confirmar != true) return;

    setState(() { _isLoadingAction = true; });
    try {
      final response = await http.post(
        Uri.parse(_cancelarReservaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'userId': widget.userId, 'bookingId': bookingId }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200) {
        bool tokenDevuelto = data['tokenDevuelto'] ?? false;
        Color colorSnack = tokenDevuelto ? Colors.green : Colors.orange;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: colorSnack, duration: const Duration(seconds: 4)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isLoadingAction = false; });
    }
  }

  void _mostrarModalCrearClase() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _CreateClassModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Normalización de ID para buscar el nombre
    String idConCeros = widget.userId.padLeft(6, '0');
    String idSinCeros = widget.userId.replaceFirst(RegExp(r'^0+'), '');
    List<dynamic> posiblesIds = [idConCeros, idSinCeros];
    if (int.tryParse(idSinCeros) != null) posiblesIds.add(int.parse(idSinCeros));

    bool isAdmin = _adminIds.contains(idConCeros);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: isAdmin 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Gestión Clases", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _mostrarModalCrearClase,
                  icon: const Icon(Icons.add_circle, color: Colors.teal),
                  label: const Text("Crear", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(backgroundColor: Colors.teal.shade50),
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Reservar Clase", style: TextStyle(color: Colors.grey, fontSize: 14)),
                // --- CORRECCIÓN AQUÍ: STREAMBUILDER PARA LEER EL NOMBRE ---
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(idConCeros).snapshots(),
                  builder: (context, snapshot) {
                    String nombre = "Usuario ${widget.userId}";
                    if (snapshot.hasData && snapshot.data!.exists) {
                       var data = snapshot.data!.data() as Map<String, dynamic>;
                       // Prioridad: nombreCompleto -> nombre -> ID
                       String completo = data['nombreCompleto'] ?? data['nombre'] ?? "";
                       if (completo.isNotEmpty) nombre = completo.split(' ')[0]; // Solo el nombre de pila
                    }
                    return Text("Hola, $nombre", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
                  },
                ),
              ],
            ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').where('userId', whereIn: posiblesIds).snapshots(),
        builder: (context, bookingSnapshot) {
          Map<String, String> misReservas = {};
          if (bookingSnapshot.hasData) {
            for (var doc in bookingSnapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              misReservas[data['groupClassId']] = doc.id;
            }
          }

          return Column(
            children: [
              Container(
                height: 90,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: 14, 
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected = isSameDay(date, _selectedDate);
                    final List<String> diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                    String nombreDia = diasSemana[date.weekday - 1];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [if (!isSelected) BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(nombreDia, style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)),
                            const SizedBox(height: 5),
                            Text("${date.day}", style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Clases del ${_selectedDate.day}/${_selectedDate.month}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('groupClasses').orderBy('fechaHoraInicio').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text("Error cargando clases"));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final todasLasClases = snapshot.data!.docs.map((doc) => GroupClass.fromFirestore(doc)).toList();

                    final clasesDelDia = todasLasClases.where((clase) {
                      var docSnapshot = snapshot.data!.docs.firstWhere((d) => d.id == clase.id);
                      Timestamp? ts = (docSnapshot.data() as Map<String, dynamic>)['fechaHoraInicio'];
                      if (ts == null) return false;
                      DateTime fechaClase = ts.toDate();
                      bool coincideDia = isSameDay(fechaClase, _selectedDate);
                      if (isAdmin) return coincideDia; 
                      bool esFutura = true;
                      if (isSameDay(DateTime.now(), _selectedDate)) {
                        esFutura = fechaClase.isAfter(DateTime.now());
                      }
                      return coincideDia && esFutura;
                    }).toList();

                    if (clasesDelDia.isEmpty) return const Center(child: Text("No hay clases disponibles"));

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: clasesDelDia.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        var doc = clasesDelDia[index];
                        var claseData = snapshot.data!.docs.firstWhere((d) => d.id == doc.id).data() as Map<String, dynamic>;
                        
                        String classId = doc.id;
                        String nombre = claseData['nombre'] ?? "Clase";
                        String monitor = claseData['monitor'] ?? "";
                        int aforoActual = claseData['aforoActual'] ?? 0;
                        int aforoMax = claseData['aforoMaximo'] ?? 12;
                        Timestamp ts = claseData['fechaHoraInicio'];
                        DateTime fechaClase = ts.toDate();
                        
                        String horario = "${DateFormat('HH:mm').format(fechaClase)} - ${DateFormat('HH:mm').format(fechaClase.add(const Duration(hours: 1)))}";
                        
                        final bool estaLlena = aforoActual >= aforoMax;
                        final MaterialColor color = _getColorPorClase(nombre);
                        final bool yaReservada = misReservas.containsKey(classId);
                        final String? bookingId = misReservas[classId];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))],
                            border: Border(left: BorderSide(color: color, width: 5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      Text(horario.split('-')[0].trim(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade800)),
                                      Text(horario.contains('-') ? horario.split('-')[1].trim() : "", style: TextStyle(fontSize: 14, color: color.shade800)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(monitor, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      yaReservada 
                                        ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)), child: const Text("RESERVADA", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)))
                                        : Row(children: [Icon(Icons.people, size: 14, color: estaLlena ? Colors.red : color), const SizedBox(width: 4), Text("${aforoActual}/${aforoMax} plazas", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: estaLlena ? Colors.red : color))])
                                    ],
                                  ),
                                ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _borrarClaseAdmin(classId),
                                  )
                                else
                                  _isLoadingAction
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : yaReservada
                                        ? IconButton(
                                            icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 30), 
                                            onPressed: () => _cancelarReserva(bookingId!, fechaClase)
                                          )
                                        : ElevatedButton(
                                            onPressed: estaLlena ? null : () => _reservarClase(classId, nombre),
                                            style: ElevatedButton.styleFrom(backgroundColor: estaLlena ? Colors.grey.shade300 : color, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                            child: Text(estaLlena ? "LLENA" : "Reservar", style: const TextStyle(fontSize: 12)),
                                          ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

// --- MODAL CREAR CLASE ---
class _CreateClassModal extends StatefulWidget {
  const _CreateClassModal();
  @override
  State<_CreateClassModal> createState() => _CreateClassModalState();
}

class _CreateClassModalState extends State<_CreateClassModal> {
  final String _apiUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/generarClasesMensuales';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _profesionalController = TextEditingController();
  bool _isLoading = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final Set<int> _selectedDays = {}; 
  int _selectedMonthOffset = 0; 

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!);
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _generar() async {
    if (_nameController.text.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rellena nombre y días")));
      return;
    }
    setState(() { _isLoading = true; });
    DateTime now = DateTime.now();
    DateTime targetDate = DateTime(now.year, now.month + _selectedMonthOffset, 1);
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': _nameController.text.trim(),
          'profesional': _profesionalController.text.trim().isEmpty ? "Staff" : _profesionalController.text.trim(),
          'diasSemana': _selectedDays.toList(),
          'hora': _selectedTime.hour,
          'minutos': _selectedTime.minute,
          'mes': targetDate.month - 1, 
          'anio': targetDate.year,
          'aforoMax': 12
        }),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        Navigator.pop(context); 
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error']), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String mesActual = DateFormat('MMMM', 'es').format(now).toUpperCase();
    String mesSiguiente = DateFormat('MMMM', 'es').format(DateTime(now.year, now.month + 1)).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      height: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Generar Clases Mensuales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 20),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre Actividad", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _profesionalController, decoration: const InputDecoration(labelText: "Monitor (Opcional)", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const Text("Días:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_dayBtn("L", 1), _dayBtn("M", 2), _dayBtn("X", 3), _dayBtn("J", 4), _dayBtn("V", 5), _dayBtn("S", 6), _dayBtn("D", 0)]),
          const SizedBox(height: 20),
          Row(children: [
              Expanded(child: InkWell(onTap: _selectTime, child: InputDecorator(decoration: const InputDecoration(labelText: "Hora", border: OutlineInputBorder()), child: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold))))),
              const SizedBox(width: 15),
              Expanded(child: InputDecorator(decoration: const InputDecoration(labelText: "Mes", border: OutlineInputBorder()), child: DropdownButton<int>(value: _selectedMonthOffset, isExpanded: true, underline: const SizedBox(), items: [DropdownMenuItem(value: 0, child: Text(mesActual)), DropdownMenuItem(value: 1, child: Text(mesSiguiente))], onChanged: (val) => setState(() => _selectedMonthOffset = val!)))),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _generar, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("GENERAR CALENDARIO"))),
        ],
      ),
    );
  }

  Widget _dayBtn(String label, int value) {
    bool selected = _selectedDays.contains(value);
    return GestureDetector(onTap: () => setState(() => selected ? _selectedDays.remove(value) : _selectedDays.add(value)), child: CircleAvatar(backgroundColor: selected ? Colors.teal : Colors.grey.shade200, child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black))));
  }
}