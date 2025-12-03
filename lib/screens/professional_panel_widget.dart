import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORTS DE PANTALLAS ---
import 'admin_patient_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'admin_create_patient_screen.dart'; 
import 'admin_time_report_screen.dart'; 
import 'alerts_list_screen.dart'; 
import 'admin_renewal_screen.dart';      
import 'admin_upload_excel_screen.dart'; 
import 'admin_edit_time_records_screen.dart';
import 'internal_management_screen.dart'; 
import 'admin_class_manager_screen.dart'; 
import 'admin_patient_resources_screens.dart';

class ProfessionalPanelWidget extends StatefulWidget {
  final String userId;
  final String userRole;

  const ProfessionalPanelWidget({super.key, required this.userId, required this.userRole});

  @override
  State<ProfessionalPanelWidget> createState() => _ProfessionalPanelWidgetState();
}

class _ProfessionalPanelWidgetState extends State<ProfessionalPanelWidget> {
  final String _ficharUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/registrarFichaje';
  bool _isLoadingFichaje = false; 
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadProfessionalName();
  }

  Future<void> _loadProfessionalName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentUserName = doc.data()?['nombreCompleto'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre: $e');
    }
  }

  // --- LÓGICA DE FICHAJE ---
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
      final String? wifiName = await NetworkInfo().getWifiName();
      if (wifiName != null) return wifiName.replaceAll('"', ''); 
    } catch (e) { /* Ignore */ }
    return null;
  }

  Future<void> _fichar(String tipo, {String? manualTime}) async {
    if (_isLoadingFichaje) return; 
    setState(() => _isLoadingFichaje = true);
    
    try {
      final String? deviceId = await _getDeviceId();
      final String? wifiSsid = await _getWifiName();
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      
      final response = await http.post(
        Uri.parse(_ficharUrl),
        headers: {
           'Content-Type': 'application/json',
           'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'userId': widget.userId, 'type': tipo, 'deviceId': deviceId,
          'wifiSsid': wifiSsid, 'manualTime': manualTime, 
        }),
      );
      
      final data = jsonDecode(response.body);

      if (!mounted) return; 

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
      } else if (response.statusCode == 409 && data['code'] == 'OPEN_SHIFT_PREVIOUS_DAY') {
        _mostrarDialogoCorreccion(data['lastEntry']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error desconocido'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingFichaje = false);
    }
  }

  void _mostrarDialogoCorreccion(String? lastEntryIso) {
    final DateTime lastEntry = lastEntryIso != null ? DateTime.parse(lastEntryIso) : DateTime.now();
    const TimeOfDay selectedTime = TimeOfDay(hour: 20, minute: 0); 
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

  // --- OTRAS FUNCIONES ---
  Future<void> _procesarPase(String userIdScanned) async {
    final String targetId = userIdScanned.trim().padLeft(6, '0');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Validando...')));
    try {
      final query = await FirebaseFirestore.instance.collection('passes').where('userId', isEqualTo: targetId).limit(1).get();
      if (!mounted) return; 
      if (query.docs.isEmpty) { _alert('Error', 'Usuario sin bonos activos.', Colors.red); return; }
      final passDoc = query.docs.first;
      final int tokens = passDoc.data()['tokensRestantes'] ?? 0;
      if (tokens <= 0) { _alert('Acceso Denegado', 'Sin tokens.', Colors.orange); return; }
      await passDoc.reference.update({'tokensRestantes': tokens - 1});
      if (mounted) _alert('ACCESO CONCEDIDO', 'Quedan ${tokens - 1} tokens.', Colors.green);
    } catch (e) { if (mounted) _alert('Error', e.toString(), Colors.red); }
  }

  void _alert(String titulo, String mensaje, Color color) {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(titulo, style: TextStyle(color: color)), content: Text(mensaje), actions: [TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))]));
  }

  void _verificarPasswordInforme() {
    final TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceso Restringido'),
        content: TextField(controller: passController, obscureText: true, autofocus: true, decoration: const InputDecoration(hintText: 'Contraseña admin', prefixIcon: Icon(Icons.lock))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
              if (passController.text.trim() == 'salufit') { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminTimeReportScreen())); } 
              else { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña incorrecta'), backgroundColor: Colors.red)); }
            }, child: const Text('Acceder')),
        ],
      ),
    );
  }

  void _showPatientActionSheet(String patientId, String patientName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(patientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 5),
            Text('ID: $patientId', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            ListTile(leading: const Icon(Icons.video_library, color: Colors.indigo), title: const Text('Gestionar Material'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPatientMaterialScreen(userId: patientId, userName: patientName))); }),
            ListTile(leading: const Icon(Icons.folder_shared, color: Colors.orange), title: const Text('Gestionar Documentos'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPatientDocumentsScreen(userId: patientId, userName: patientName, viewerRole: widget.userRole))); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.userRole == 'admin';

    return SafeArea(
      child: Column(
        children: [
          // 1. CABECERA COMPACTA
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.teal, size: 24),
                SizedBox(width: 10),
                Text('Panel Profesional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
          ),

          // 2. GRID DE BOTONES
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('timeClockRecords').where('userId', isEqualTo: widget.userId).orderBy('timestamp', descending: true).limit(1).snapshots(),
            builder: (context, snapshotFichaje) {
              bool isWorking = false;
              if (snapshotFichaje.hasData && snapshotFichaje.data!.docs.isNotEmpty) {
                final data = snapshotFichaje.data!.docs.first.data() as Map<String, dynamic>;
                if (data['type'] == 'IN') isWorking = true;
              }

              final List<Widget> menuItems = [
                _MenuGridCard(
                  icon: isWorking ? Icons.timer : Icons.login,
                  label: isWorking ? 'EN TURNO\n(Salir)' : 'FICHAR\nENTRADA',
                  color: isWorking ? Colors.green : Colors.grey,
                  isHighlight: isWorking, 
                  isLoading: _isLoadingFichaje,
                  onTap: () => _fichar(isWorking ? 'OUT' : 'IN'),
                ),
                _MenuGridCard(
                  icon: Icons.qr_code_scanner, label: 'Escanear\nEntrada', color: Colors.blueGrey,
                  onTap: () async { final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen())); if (res != null && mounted) _procesarPase(res); },
                ),
                _MenuGridCard(
                  icon: Icons.people, label: 'Gestión\nClases', color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminClassManagerScreen(currentUserId: widget.userId))),
                ),
                _MenuGridCard(
                  icon: Icons.video_library, label: 'Gestión\nMaterial', color: Colors.indigo,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPatientListScreen(viewerRole: widget.userRole, onUserSelected: (uid, name) => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPatientMaterialScreen(userId: uid, userName: name)))))),
                ),
                _MenuGridCard(
                  icon: Icons.folder_shared, label: 'Gestión\nDocs', color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPatientListScreen(viewerRole: widget.userRole, onUserSelected: (uid, name) => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminPatientDocumentsScreen(userId: uid, userName: name, viewerRole: widget.userRole)))))),
                ),
                // CHATS
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('internal_chats').where('participants', arrayContains: widget.userId).snapshots(),
                  builder: (c, s) {
                    int count = 0;
                    if(s.hasData) {
                      for(var d in s.data!.docs) {
                        count += ((d.data() as Map)['unreadCount_${widget.userId}'] as num? ?? 0).toInt();
                      }
                    }
                    return Badge(isLabelVisible: count > 0, label: Text('$count'), child: _MenuGridCard(icon: Icons.chat, label: 'Chats\nEquipo', color: Colors.cyan, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => InternalManagementScreen(currentUserId: widget.userId, viewType: 'chat', userRole: widget.userRole)))));
                  }
                ),
                // TAREAS
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('internal_tasks').where('assignedToId', isEqualTo: widget.userId).where('status', isEqualTo: 'pending').snapshots(),
                  builder: (c, s) {
                    final int count = s.hasData ? s.data!.docs.length : 0;
                    return Badge(isLabelVisible: count > 0, label: Text('$count'), child: _MenuGridCard(icon: Icons.check_circle_outline, label: 'Mis\nTareas', color: Colors.deepPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => InternalManagementScreen(currentUserId: widget.userId, viewType: 'tasks', userRole: widget.userRole)))));
                  }
                ),
              ];

              if (isAdmin) {
                menuItems.addAll([
                  _MenuGridCard(icon: Icons.person_add_alt_1, label: 'Nuevo\nPaciente', color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminCreatePatientScreen()))),
                  _MenuGridCard(icon: Icons.autorenew, label: 'Renovar\nBonos', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminRenewalScreen()))),
                  _MenuGridCard(icon: Icons.upload_file, label: 'Importar\nExcel', color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminUploadExcelScreen()))),
                  _MenuGridCard(icon: Icons.edit_calendar, label: 'Corregir\nFichajes', color: Colors.pink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminEditTimeRecordsScreen()))),
                  _MenuGridCard(icon: Icons.picture_as_pdf, label: 'Informes\nRRHH', color: Colors.brown, onTap: _verificarPasswordInforme),
                ]);
              }

              return Column(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('exercise_assignments').where('feedback.alerta', isEqualTo: true).snapshots(),
                    builder: (c, s) {
                      if (!s.hasData || s.data!.docs.isEmpty) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AlertsListScreen(viewerRole: widget.userRole))),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.warning, color: Colors.red, size: 20), const SizedBox(width: 8), Text('${s.data!.docs.length} ALERTAS ACTIVAS', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                          ),
                        ),
                      );
                    }
                  ),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    padding: const EdgeInsets.all(15),
                    crossAxisCount: 4, 
                    crossAxisSpacing: 8, 
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85, 
                    children: menuItems,
                  ),
                ],
              );
            },
          ),

          const Divider(height: 1),

          // 3. AGENDA 
          if (_currentUserName.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    color: Colors.grey.shade50,
                    child: const Text('PRÓXIMAS CITAS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('appointments').where('profesional', isEqualTo: _currentUserName).where('fechaHoraInicio', isGreaterThan: Timestamp.now()).orderBy('fechaHoraInicio').limit(20).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final citas = snapshot.data!.docs;
                        if (citas.isEmpty) return const Center(child: Text('Agenda libre hoy', style: TextStyle(color: Colors.grey)));

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          itemCount: citas.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final data = citas[index].data() as Map<String, dynamic>;
                            final DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
                            
                            return ListTile(
                              visualDensity: VisualDensity.compact, 
                              leading: Text(DateFormat('HH:mm').format(fecha), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                              title: Text(data['pacienteNombre'] ?? 'Paciente', style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(data['especialidad'] ?? '', style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                              onTap: () => _showPatientActionSheet(data['userId'] ?? '', data['pacienteNombre'] ?? ''),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// TARJETA DE MENÚ OPTIMIZADA
class _MenuGridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isHighlight;
  final bool isLoading;

  const _MenuGridCard({
    required this.icon, required this.label, required this.color, required this.onTap,
    this.isHighlight = false, this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlight ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05), // SOLUCIÓN SEGURA
            blurRadius: 4, 
            offset: const Offset(0, 2)
          )
        ],
        border: isHighlight ? null : Border.all(color: Colors.grey[200]!), 
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: isHighlight ? Colors.white : color), 
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
                          color: isHighlight ? Colors.white : Colors.grey[800],
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}