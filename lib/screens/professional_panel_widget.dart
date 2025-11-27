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
    bool isAdmin = widget.userRole == 'admin';

    // Definimos los botones
    List<Widget> menuItems = [
      // --- PARA TODOS (Staff) ---
      _MenuGridCard(
        icon: Icons.qr_code_scanner,
        label: 'Escanear Entrada',
        color: Colors.blueGrey,
        onTap: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
          if (res != null && mounted) _procesarPase(res);
        },
      ),
      _MenuGridCard(
        icon: Icons.people_alt,
        label: 'Listado Pacientes',
        color: Colors.blue,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPatientListScreen(viewerRole: widget.userRole))),
      ),
      
      // --- GESTIÓN DE CLASES ---
      _MenuGridCard(
        icon: Icons.calendar_month,
        label: 'Gestión Clases',
        color: Colors.teal,
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => AdminClassManagerScreen(currentUserId: widget.userId))
        ),
      ),

      // --- GESTIÓN RÁPIDA MATERIAL ---
      _MenuGridCard(
        icon: Icons.video_library, 
        label: 'Gestión Material',
        color: Colors.indigo,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPatientListScreen(
                viewerRole: widget.userRole,
                onUserSelected: (uid, name) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => AdminPatientMaterialScreen(userId: uid, userName: name))
                  );
                },
              ),
            ),
          );
        },
      ),

      // --- GESTIÓN RÁPIDA DOCUMENTOS ---
      _MenuGridCard(
        icon: Icons.folder_shared, 
        label: 'Gestión Docs',
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPatientListScreen(
                viewerRole: widget.userRole,
                onUserSelected: (uid, name) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => AdminPatientDocumentsScreen(userId: uid, userName: name, viewerRole: widget.userRole))
                  );
                },
              ),
            ),
          );
        },
      ),

      // --- BOTÓN 1: CHATS / EQUIPO (Badge: Mensajes no leídos) ---
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('internal_chats')
            .where('participants', arrayContains: widget.userId)
            .snapshots(),
        builder: (context, chatSnap) {
          int chatsCount = 0;
          if (chatSnap.hasData) {
            for (var doc in chatSnap.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              chatsCount += (data['unreadCount_${widget.userId}'] as num? ?? 0).toInt();
            }
          }
          
          return Badge(
            isLabelVisible: chatsCount > 0,
            label: Text("$chatsCount"),
            backgroundColor: Colors.red,
            child: _MenuGridCard(
              icon: Icons.chat, 
              label: 'Chats / Equipo',
              color: Colors.cyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InternalManagementScreen(currentUserId: widget.userId, viewType: 'chat')),
              ),
            ),
          );
        }
      ),

      // --- BOTÓN 2: TAREAS (Badge: Tareas pendientes) ---
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('internal_tasks')
            .where('assignedToId', isEqualTo: widget.userId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, taskSnap) {
          int tasksCount = taskSnap.hasData ? taskSnap.data!.docs.length : 0;
          
          return Badge(
            isLabelVisible: tasksCount > 0,
            label: Text("$tasksCount"),
            backgroundColor: Colors.red,
            child: _MenuGridCard(
              icon: Icons.check_circle_outline, 
              label: 'Tareas',
              color: Colors.deepPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InternalManagementScreen(currentUserId: widget.userId, viewType: 'tasks')),
              ),
            ),
          );
        }
      ),
    ];

    // --- SOLO ADMIN ---
    if (isAdmin) {
      menuItems.addAll([
        _MenuGridCard(
          icon: Icons.person_add_alt_1,
          label: 'Nuevo Paciente',
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreatePatientScreen())),
        ),
        _MenuGridCard(
          icon: Icons.autorenew,
          label: 'Renovación Bonos',
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRenewalScreen())),
        ),
        _MenuGridCard(
          icon: Icons.upload_file,
          label: 'Importar Excel',
          color: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUploadExcelScreen())),
        ),
        _MenuGridCard(
          icon: Icons.edit_calendar,
          label: 'Corregir Fichajes',
          color: Colors.pink, 
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEditTimeRecordsScreen())),
        ),
        _MenuGridCard(
          icon: Icons.picture_as_pdf,
          label: 'Informes Fichajes',
          color: Colors.brown,
          onTap: _verificarPasswordInforme,
        ),
      ]);
    }

    return Container(
      // ELIMINADO: color: const Color(0xFFF5F7FA) -> TRANSPARENTE
      child: SafeArea(
        child: Column(
          children: [
            // CABECERA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.teal, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Panel Profesional',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
              ),
            ),

            // 1. ALERTAS
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
                      title: Text('$alertasCount ALERTAS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Revisar feedback', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AlertsListScreen(viewerRole: widget.userRole)));
                      },
                    ),
                  ),
                );
              }
            ),

            // 2. FICHAJE
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: _buildFichajeCard()),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(thickness: 1),
            ),
            
            // 3. GRID COMPACTO (3 COLUMNAS)
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: 3, 
                crossAxisSpacing: 10, 
                mainAxisSpacing: 10,
                childAspectRatio: 0.85, 
                children: menuItems,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(15), 
            boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
            border: Border.all(color: isWorking ? Colors.green.shade200 : Colors.grey.shade300)
          ),
          child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isWorking ? 'EN JORNADA' : 'FUERA DE JORNADA', style: TextStyle(color: isWorking ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(isWorking ? "Entrada: ${DateFormat('HH:mm').format(lastTime ?? DateTime.now())}" : 'Sin fichar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                  Icon(Icons.access_time_filled, color: isWorking ? Colors.green : Colors.grey, size: 24)
              ]),
              const SizedBox(height: 10),
              if (_statusMessage.isNotEmpty) Text(_statusMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
              SizedBox(width: double.infinity, height: 40, child: _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton.icon(onPressed: () => _fichar(isWorking ? 'OUT' : 'IN'), icon: Icon(isWorking ? Icons.exit_to_app : Icons.login, size: 18), label: Text(isWorking ? 'SALIR' : 'ENTRAR', style: const TextStyle(fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: isWorking ? Colors.red.shade400 : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))))
            ]),
        );
      },
    );
  }
}

// --- TARJETA DE MENÚ ---
class _MenuGridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuGridCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: color), 
                ),
                const SizedBox(height: 8),
                Flexible( 
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      height: 1.2
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