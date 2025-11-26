import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

// --- IMPORTS DE TODAS LAS PANTALLAS ---
import 'admin_patient_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'admin_create_patient_screen.dart'; 
import 'admin_time_report_screen.dart'; 
import 'alerts_list_screen.dart'; 
import 'admin_renewal_screen.dart';      
import 'admin_upload_excel_screen.dart'; 
import 'admin_edit_time_records_screen.dart'; // <--- NUEVO IMPORT

class ProfessionalPanelWidget extends StatefulWidget {
  final String userId;
  final String userRole;

  const ProfessionalPanelWidget({super.key, required this.userId, required this.userRole});

  @override
  State<ProfessionalPanelWidget> createState() => _ProfessionalPanelWidgetState();
}

class _ProfessionalPanelWidgetState extends State<ProfessionalPanelWidget> {
  final String _ficharUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/registrarFichaje';
  bool _isLoading = false;
  String _statusMessage = ''; 

  // --- LÓGICA TÉCNICA (Fichaje) ---
  Future<String?> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) return (await deviceInfo.androidInfo).id; 
      if (Platform.isIOS) return (await deviceInfo.iosInfo).identifierForVendor;
    } catch (e) { /* Ignore */ }
    return 'unknown_device';
  }

  Future<String?> _getWifiName() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) return null; 
    }
    try {
      String? wifiName = await NetworkInfo().getWifiName();
      if (wifiName != null) return wifiName.replaceAll('"', ''); 
    } catch (e) { /* Ignore */ }
    return null;
  }

  Future<void> _fichar(String tipo, {String? manualTime}) async {
    setState(() { _isLoading = true; _statusMessage = 'Validando...'; });
    try {
      String? deviceId = await _getDeviceId();
      String? wifiSsid = await _getWifiName();
      
      final response = await http.post(
        Uri.parse(_ficharUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId, 'type': tipo, 'deviceId': deviceId,
          'wifiSsid': wifiSsid, 'manualTime': manualTime, 
        }),
      );
      final data = jsonDecode(response.body);

      if (!mounted) return; 

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
        setState(() { _statusMessage = ''; });
      } else if (response.statusCode == 409 && data['code'] == 'OPEN_SHIFT_PREVIOUS_DAY') {
        _mostrarDialogoCorreccion(data['lastEntry']);
      } else {
        setState(() { _statusMessage = data['error'] ?? 'Error desconocido'; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_statusMessage), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() { _statusMessage = 'Error: $e'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _mostrarDialogoCorreccion(String? lastEntryIso) {
    DateTime lastEntry = lastEntryIso != null ? DateTime.parse(lastEntryIso) : DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 0); 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Turno anterior abierto!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Olvidaste salir el ${DateFormat('dd/MM').format(lastEntry)}. Indica hora de salida:"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? time = await showTimePicker(context: context, initialTime: selectedTime);
                if (time != null && context.mounted) {
                  final fechaSalida = DateTime(lastEntry.year, lastEntry.month, lastEntry.day, time.hour, time.minute);
                  Navigator.pop(context); 
                  _fichar('OUT', manualTime: fechaSalida.toIso8601String());
                }
              },
              child: const Text('Seleccionar Hora'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _procesarPase(String userIdScanned) async {
    String targetId = userIdScanned.trim().padLeft(6, '0');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Validando...')));
    try {
      var query = await FirebaseFirestore.instance.collection('passes').where('userId', isEqualTo: targetId).limit(1).get();
      
      if (!mounted) return; 

      if (query.docs.isEmpty) {
         _alert('Error', "Usuario sin bonos activos.", Colors.red);
         return;
      }
      var passDoc = query.docs.first;
      int tokens = passDoc.data()['tokensRestantes'] ?? 0;

      if (tokens <= 0) {
         _alert('Acceso Denegado', "Sin tokens.", Colors.orange);
         return;
      }
      await passDoc.reference.update({'tokensRestantes': tokens - 1});
      
      if (mounted) _alert('ACCESO CONCEDIDO', "Quedan ${tokens - 1} tokens.", Colors.green);
    } catch (e) { 
      if (mounted) _alert('Error', e.toString(), Colors.red); 
    }
  }

  void _alert(String titulo, String mensaje, Color color) {
    showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: Text(titulo, style: TextStyle(color: color)),
        content: Text(mensaje),
        actions: [TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))]
      )
    );
  }

  void _verificarPasswordInforme() {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceso Restringido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Contraseña de administrador:'),
            const SizedBox(height: 15),
            TextField(controller: passController, obscureText: true, autofocus: true, decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (passController.text.trim() == 'salufit') {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminTimeReportScreen()));
              } else {
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña incorrecta'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Acceder')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.teal.shade50,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                'Panel Profesional',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),

            // 1. ALERTAS DE FEEDBACK
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('exercise_assignments').where('feedback.alerta', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox(); 
                
                int alertasCount = snapshot.data!.docs.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Card(
                    color: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.notification_important, color: Colors.white, size: 30),
                      title: Text('$alertasCount PACIENTES CON PROBLEMAS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Revisa el feedback negativo', style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AlertsListScreen(viewerRole: widget.userRole)));
                      },
                    ),
                  ),
                );
              }
            ),

            // 2. FICHAJE
            Padding(padding: const EdgeInsets.all(20.0), child: _buildFichajeCard()),
            const Divider(thickness: 2, indent: 20, endIndent: 20),
            
            // 3. MENÚ DE HERRAMIENTAS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  const Text('HERRAMIENTAS DE GESTIÓN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  // --- BOTONES PARA TODOS (PRO Y ADMIN) ---
                  _AdminButton(
                    icon: Icons.qr_code_scanner, 
                    text: 'Escanear Entrada', 
                    onTap: () async {
                       final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
                       if (res != null && mounted) _procesarPase(res);
                    }
                  ),
                  const SizedBox(height: 15),
                  
                  _AdminButton(
                    icon: Icons.people_alt, 
                    text: 'Listado Pacientes', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPatientListScreen(viewerRole: widget.userRole)))
                  ),

                  // --- BOTONES SOLO PARA ADMIN ---
                  if (widget.userRole == 'admin') ...[
                    const SizedBox(height: 25),
                    const Text('ADMINISTRACIÓN', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // AÑADIR PACIENTE
                    _AdminButton(
                      icon: Icons.person_add, 
                      text: 'Añadir Nuevo Paciente', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreatePatientScreen()))
                    ),
                    const SizedBox(height: 10),

                    // RENOVACIÓN MASIVA
                    _AdminButton(
                      icon: Icons.autorenew, 
                      text: 'Renovación Mensual Bonos', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRenewalScreen()))
                    ),
                    const SizedBox(height: 10),

                    // IMPORTAR EXCEL
                    _AdminButton(
                      icon: Icons.upload_file, 
                      text: 'Importar Citas (Excel)', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUploadExcelScreen()))
                    ),
                    const SizedBox(height: 10),

                    // GESTIÓN DE FICHAJES (CORRECCIONES) - NUEVO
                    _AdminButton(
                      icon: Icons.edit_calendar, 
                      text: 'Corregir/Editar Fichajes', 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEditTimeRecordsScreen()))
                    ),
                    const SizedBox(height: 10),

                    // INFORMES
                    _AdminButton(
                      icon: Icons.description, 
                      text: 'Informe Fichajes (PDF)', 
                      onTap: _verificarPasswordInforme
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFichajeCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('timeClockRecords').where('userId', isEqualTo: widget.userId).orderBy('timestamp', descending: true).limit(1).snapshots(),
      builder: (context, snapshot) {
        bool isWorking = false; DateTime? lastTime;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          if (data['type'] == 'IN') { isWorking = true; lastTime = (data['timestamp'] as Timestamp).toDate(); }
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: isWorking ? Colors.green.shade200 : Colors.grey.shade300)
          ),
          child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isWorking ? 'JORNADA EN CURSO' : 'FUERA DE JORNADA', style: TextStyle(color: isWorking ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(isWorking ? "Entrada: ${DateFormat('HH:mm').format(lastTime ?? DateTime.now())}" : 'Esperando fichaje', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ]),
                  Icon(Icons.access_time_filled, color: isWorking ? Colors.green : Colors.grey, size: 30)
              ]),
              const SizedBox(height: 20),
              if (_statusMessage.isNotEmpty) Text(_statusMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
              SizedBox(width: double.infinity, height: 55, child: _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton.icon(onPressed: () => _fichar(isWorking ? 'OUT' : 'IN'), icon: Icon(isWorking ? Icons.exit_to_app : Icons.login), label: Text(isWorking ? 'FICHAR SALIDA' : 'FICHAR ENTRADA'), style: ElevatedButton.styleFrom(backgroundColor: isWorking ? Colors.red.shade400 : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))
            ]),
        );
      },
    );
  }
}

class _AdminButton extends StatelessWidget {
  final IconData icon; final String text; final VoidCallback onTap;
  const _AdminButton({required this.icon, required this.text, required this.onTap});
  @override Widget build(BuildContext context) { return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.teal.shade100)), child: ListTile(leading: Icon(icon, color: Colors.teal), title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.teal), onTap: onTap)); }
}