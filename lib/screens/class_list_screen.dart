import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_class.dart';
import '../widgets/salufit_scaffold.dart'; // <--- CAMBIO

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

  // --- LÓGICA VISUAL (Iconos Actualizados) ---
  Map<String, dynamic> _getClassVisuals(String nombreClase) {
    String nombre = nombreClase.toLowerCase();
    
    if (nombre.contains('entrenamiento')) {
      return {
        'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 
        'icon': Icons.fitness_center, 
        'textColor': Colors.red.shade900
      };
    } 
    if (nombre.contains('meditación') || nombre.contains('meditacion')) {
      return {
        'colors': [const Color(0xFF7B1FA2), const Color(0xFFBA68C8)], 
        'icon': Icons.self_improvement, 
        'textColor': Colors.purple.shade900
      };
    }
    if (nombre.contains('tribu')) {
      return {
        'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 
        'icon': Icons.directions_walk, 
        'textColor': Colors.orange.shade900
      };
    }
    return {
      'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 
      'icon': Icons.sports_gymnastics, 
      'textColor': Colors.blue.shade900
    };
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
    String idConCeros = widget.userId.padLeft(6, '0');
    String idSinCeros = widget.userId.replaceFirst(RegExp(r'^0+'), '');
    List<dynamic> posiblesIds = [idConCeros, idSinCeros];
    if (int.tryParse(idSinCeros) != null) posiblesIds.add(int.parse(idSinCeros));
    
    // OBTENEMOS EMAIL PARA LA CONSULTA SEGURA
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    bool isAdmin = _adminIds.contains(idConCeros);

    return SalufitScaffold( // <--- CAMBIO A WIDGET CON FONDO
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
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(idConCeros).snapshots(),
                  builder: (context, snapshot) {
                    String nombre = "Usuario ${widget.userId}";
                    if (snapshot.hasData && snapshot.data!.exists) {
                       var data = snapshot.data!.data() as Map<String, dynamic>;
                       String completo = data['nombreCompleto'] ?? data['nombre'] ?? "";
                       if (completo.isNotEmpty) nombre = completo.split(' ')[0]; 
                    }
                    return Text("Hola, $nombre", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
                  },
                ),
              ],
            ),
      ),
      // CAMBIAMOS A CONSULTA POR EMAIL SI ES POSIBLE
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings')
            .where('userEmail', isEqualTo: userEmail) // Búsqueda por email (segura)
            .snapshots(),
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
              // CALENDARIO HORIZONTAL
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
                          color: isSelected ? Colors.teal : Colors.white,
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
                        final bool yaReservada = misReservas.containsKey(classId);
                        // Necesitamos el bookingId, pero si usamos la query por email, lo tenemos en el mapa
                        String? bookingId;
                        if(yaReservada) bookingId = misReservas[classId];

                        // ESTILOS VISUALES
                        Map<String, dynamic> visual = _getClassVisuals(nombre);
                        List<Color> gradientColors = visual['colors'];
                        IconData iconData = visual['icon'];
                        Color textBtnColor = visual['textColor'];

                        return Container(
                          height: 120, 
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Stack(
                            children: [
                              // ICONO DE FONDO DECORATIVO
                              Positioned(
                                right: -15,
                                bottom: -15,
                                child: Icon(iconData, size: 130, color: Colors.white.withOpacity(0.15)),
                              ),
                              
                              // CONTENIDO
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  children: [
                                    // COLUMNA HORA
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(horario.split('-')[0].trim(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                          Text(horario.contains('-') ? horario.split('-')[1].trim() : "", style: const TextStyle(fontSize: 14, color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    
                                    // INFO CENTRAL
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text("Monitor: $monitor", style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.group, size: 12, color: Colors.white.withOpacity(0.8)),
                                                const SizedBox(width: 4),
                                                Text("${aforoActual}/${aforoMax}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    
                                    // ZONA DERECHA: BOTÓN
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end, 
                                      children: [
                                        
                                        // BOTÓN DE ACCIÓN
                                        if (yaReservada)
                                          ElevatedButton(
                                            onPressed: () => _cancelarReserva(bookingId!, fechaClase),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white, 
                                              foregroundColor: Colors.red, 
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              minimumSize: const Size(80, 30)
                                            ),
                                            child: const Text("CANCELAR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        else
                                          ElevatedButton(
                                            onPressed: estaLlena ? null : () => _reservarClase(classId, nombre),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white, 
                                              foregroundColor: textBtnColor, 
                                              disabledBackgroundColor: Colors.white24,
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              minimumSize: const Size(80, 30)
                                            ),
                                            child: Text(estaLlena ? "LLENA" : "RESERVAR", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),

                                        // ADMIN DELETE
                                        if (isAdmin)
                                          InkWell(
                                            onTap: () => _borrarClaseAdmin(classId),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Icon(Icons.delete, color: Colors.white.withOpacity(0.7), size: 18),
                                            ),
                                          )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
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

// --- MODAL CREAR CLASE (SIN CAMBIOS) ---
class _CreateClassModal extends StatefulWidget {
  const _CreateClassModal();
  @override
  State<_CreateClassModal> createState() => _CreateClassModalState();
}

class _CreateClassModalState extends State<_CreateClassModal> {
  final String _apiUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/generarClasesMensuales';
  final TextEditingController _profesionalController = TextEditingController();
  
  bool _isLoading = false;
  String _loadingStatus = "Generar Calendario";
  final List<TimeOfDay> _selectedTimes = [];
  final Set<int> _selectedDays = {}; 
  int _selectedMonthOffset = 0; 
  String? _selectedClassType; 

  final Map<String, String> _tiposYProfesionales = {
    'Ejercicio Terapéutico': 'Álvaro, David e Ibtissam',
    'Entrenamiento Grupal': 'Silvio Marin',
    'Meditación Grupal': 'Ignacio Clavero',
    'Tribu Activa >70': 'Silvio Marin',
  };

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: const TimeOfDay(hour: 17, minute: 30),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!);
      },
    );
    if (picked != null) {
      bool existe = _selectedTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute);
      if (!existe) {
        setState(() {
          _selectedTimes.add(picked);
          _selectedTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        });
      }
    }
  }

  void _removeTime(TimeOfDay time) { setState(() => _selectedTimes.remove(time)); }

  Future<void> _generar() async {
    if (_selectedClassType == null || _selectedDays.isEmpty || _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta tipo, días u horas")));
      return;
    }
    setState(() { _isLoading = true; });
    DateTime now = DateTime.now();
    DateTime targetDate = DateTime(now.year, now.month + _selectedMonthOffset, 1);
    int totalCreated = 0;
    int errors = 0;

    for (int i = 0; i < _selectedTimes.length; i++) {
      TimeOfDay time = _selectedTimes[i];
      setState(() => _loadingStatus = "Creando horario ${time.hour}:${time.minute.toString().padLeft(2,'0')}...");
      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': _selectedClassType,
            'profesional': _profesionalController.text.trim(),
            'diasSemana': _selectedDays.toList(),
            'hora': time.hour,
            'minutos': time.minute,
            'mes': targetDate.month - 1, 
            'anio': targetDate.year,
            'aforoMax': 12
          }),
        );
        if (response.statusCode == 200) totalCreated++; else errors++;
      } catch (e) { errors++; }
    }

    if (mounted) {
      Navigator.pop(context); 
      if (errors == 0) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Éxito! Creadas clases para $totalCreated horarios."), backgroundColor: Colors.green));
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Proceso terminado con $errors errores."), backgroundColor: Colors.orange));
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String mesActual = DateFormat('MMMM', 'es').format(now).toUpperCase();
    String mesSiguiente = DateFormat('MMMM', 'es').format(DateTime(now.year, now.month + 1)).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      height: 700, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Generar Clases Mensuales", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Tipo de Actividad", border: OutlineInputBorder()),
            value: _selectedClassType,
            items: _tiposYProfesionales.keys.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedClassType = val;
                if (val != null) _profesionalController.text = _tiposYProfesionales[val]!;
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(controller: _profesionalController, decoration: const InputDecoration(labelText: "Monitor/es", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const Text("Días de la semana:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_dayBtn("L", 1), _dayBtn("M", 2), _dayBtn("X", 3), _dayBtn("J", 4), _dayBtn("V", 5), _dayBtn("S", 6), _dayBtn("D", 0)]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Horarios de inicio:", style: TextStyle(fontWeight: FontWeight.bold)), TextButton.icon(onPressed: _selectTime, icon: const Icon(Icons.access_time, size: 18), label: const Text("AÑADIR HORA"))]),
          if (_selectedTimes.isEmpty) const Text("Ninguna hora seleccionada", style: TextStyle(color: Colors.grey, fontSize: 12)) else Wrap(spacing: 8.0, children: _selectedTimes.map((time) => Chip(label: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'), deleteIcon: const Icon(Icons.close, size: 18), onDeleted: () => _removeTime(time), backgroundColor: Colors.teal.shade50, labelStyle: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold))).toList()),
          const SizedBox(height: 20),
          InputDecorator(decoration: const InputDecoration(labelText: "Mes a generar", border: OutlineInputBorder()), child: DropdownButton<int>(value: _selectedMonthOffset, isExpanded: true, underline: const SizedBox(), items: [DropdownMenuItem(value: 0, child: Text(mesActual)), DropdownMenuItem(value: 1, child: Text(mesSiguiente))], onChanged: (val) => setState(() => _selectedMonthOffset = val!))),
          const Spacer(),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _generar, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), child: _isLoading ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), const SizedBox(width: 15), Text(_loadingStatus)]) : const Text("GENERAR CALENDARIO"))),
        ],
      ),
    );
  }

  Widget _dayBtn(String label, int value) {
    bool selected = _selectedDays.contains(value);
    return GestureDetector(onTap: () => setState(() => selected ? _selectedDays.remove(value) : _selectedDays.add(value)), child: CircleAvatar(backgroundColor: selected ? Colors.teal : Colors.grey.shade200, child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black))));
  }
}