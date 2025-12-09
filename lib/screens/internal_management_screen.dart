import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Ya no necesitamos importar el hub aquí porque el botón estará fuera

class InternalManagementScreen extends StatelessWidget {
  final String currentUserId;
  final String userRole; 
  final String viewType; // 'chat' o 'tasks'
  
  const InternalManagementScreen({
    super.key, 
    required this.currentUserId,
    required this.userRole,
    required this.viewType, 
  });

  @override
  Widget build(BuildContext context) {
    final bool isChat = viewType == 'chat';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isChat ? 'Comunicación' : 'Gestión de Tareas', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: isChat ? Colors.cyan : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isChat 
          ? _StaffDirectoryTab(currentUserId: currentUserId, userRole: userRole)
          : _TaskManagerTab(currentUserId: currentUserId),
    );
  }
}

// --- PESTAÑA 1: DIRECTORIO Y DIFUSIÓN ---
class _StaffDirectoryTab extends StatelessWidget {
  final String currentUserId;
  final String userRole;

  const _StaffDirectoryTab({required this.currentUserId, required this.userRole});

  String _getChatId(String peerId) {
    return currentUserId.compareTo(peerId) < 0 
        ? '${currentUserId}_$peerId' 
        : '${peerId}_$currentUserId';
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = userRole == 'admin' || userRole == 'administrador';

    return Column(
      children: [
        // --- SECCIÓN DE DIFUSIÓN (SOLO ADMINS) ---
        if (isAdmin) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: Row(
              children: [
                Icon(Icons.campaign, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                Text('CANALES DE DIFUSIÓN', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          _BroadcastTile(
            title: '📢 A TODOS LOS PROFESIONALES',
            subtitle: 'Mensaje emergente al iniciar sesión',
            color: Colors.orange.shade100,
            iconColor: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _BroadcastChatScreen(currentUserId: currentUserId, targetAudience: 'profesional'))),
          ),
          _BroadcastTile(
            title: '📢 A TODOS LOS CLIENTES',
            subtitle: 'Avisos generales para pacientes',
            color: Colors.blue.shade100,
            iconColor: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _BroadcastChatScreen(currentUserId: currentUserId, targetAudience: 'cliente'))),
          ),
          const Divider(thickness: 1),
        ],

        // --- LISTA DE CHATS PRIVADOS ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users')
                .where('rol', whereIn: ['admin', 'profesional', 'administrador']) 
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Filtramos usuarios fantasma y a uno mismo
              final docs = snapshot.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final String nombre = data['nombreCompleto'] ?? data['nombre'] ?? '';
                return d.id != currentUserId && nombre.trim().isNotEmpty;
              }).toList(); 

              if (docs.isEmpty) {
                return const Center(child: Text('No hay otros compañeros registrados.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(15),
                itemCount: docs.length,
                separatorBuilder: (c, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final String nombre = data['nombreCompleto'] ?? data['nombre'] ?? 'Compañero';
                  final String rol = (data['rol'] ?? 'Staff').toString().toUpperCase();
                  final String staffId = docs[index].id;
                  final String chatId = _getChatId(staffId);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => _ChatScreen(myId: currentUserId, peerId: staffId, peerName: nombre))
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.cyan.shade50,
                          child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('internal_chats').doc(chatId).snapshots(),
                              builder: (context, chatSnap) {
                                if (chatSnap.hasData && chatSnap.data!.exists) {
                                  final chatData = chatSnap.data!.data() as Map<String, dynamic>;
                                  final int unread = (chatData['unreadCount_$currentUserId'] as num? ?? 0).toInt();
                                  if (unread > 0) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    );
                                  }
                                }
                                return const SizedBox();
                              },
                            )
                          ],
                        ),
                        subtitle: Text(rol, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
}

class _BroadcastTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _BroadcastTile({required this.title, required this.subtitle, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.campaign, color: iconColor, size: 30),
        title: Text(title, style: TextStyle(color: iconColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.6))),
        trailing: Icon(Icons.arrow_forward, color: iconColor),
      ),
    );
  }
}

// --- PANTALLA DE DIFUSIÓN (NUEVA) ---
class _BroadcastChatScreen extends StatefulWidget {
  final String currentUserId;
  final String targetAudience; // 'profesional' o 'cliente'

  const _BroadcastChatScreen({required this.currentUserId, required this.targetAudience});

  @override
  State<_BroadcastChatScreen> createState() => _BroadcastChatScreenState();
}

class _BroadcastChatScreenState extends State<_BroadcastChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  void _enviarDifusion() {
    final String text = _msgController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _msgController.clear();

    // Guardamos en la colección 'broadcasts'
    FirebaseFirestore.instance.collection('broadcasts').add({
      'senderId': widget.currentUserId,
      'text': text,
      'targetAudience': widget.targetAudience, // profesional / cliente
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [], // Lista vacía, se irá llenando cuando la gente lo vea
      'isActive': true // Por si quieres desactivar anuncios viejos en el futuro
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPro = widget.targetAudience == 'profesional';
    final Color themeColor = isPro ? Colors.orange : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPro ? 'Difusión a Profesionales' : 'Difusión a Clientes'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: themeColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: themeColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Todo lo que escribas aquí aparecerá en una ventana emergente a todos los ${isPro ? "profesionales" : "clientes"} la próxima vez que entren.', style: TextStyle(color: themeColor.withValues(alpha: 0.8), fontSize: 12))),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('broadcasts')
                    .where('targetAudience', isEqualTo: widget.targetAudience)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msgs = snapshot.data!.docs;

                  if (msgs.isEmpty) {
                    return const Center(child: Text('No hay mensajes de difusión activos.', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final data = msgs[index].data() as Map<String, dynamic>;
                      final DateTime? fecha = (data['timestamp'] as Timestamp?)?.toDate();
                      final String fechaStr = fecha != null ? DateFormat('dd/MM/yy HH:mm').format(fecha) : '...';
                      final int vistos = (data['readBy'] as List?)?.length ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        color: Colors.white,
                        child: ListTile(
                          title: Text(data['text'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Enviado: $fechaStr'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                            child: Text('Visto por: $vistos', style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _msgController, decoration: InputDecoration(hintText: 'Escribe el anuncio...', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)))),
                  const SizedBox(width: 8),
                  CircleAvatar(backgroundColor: themeColor, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _enviarDifusion)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE CHAT PRIVADO ---
class _ChatScreen extends StatefulWidget {
  final String myId;
  final String peerId;
  final String peerName;

  const _ChatScreen({required this.myId, required this.peerId, required this.peerName});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  
  String get chatId => widget.myId.compareTo(widget.peerId) < 0 
      ? '${widget.myId}_${widget.peerId}' 
      : '${widget.peerId}_${widget.myId}';

  @override
  void initState() {
    super.initState();
    _resetUnreadCounter();
  }

  void _resetUnreadCounter() {
    FirebaseFirestore.instance.collection('internal_chats').doc(chatId).set({
      'unreadCount_${widget.myId}': 0,
      'participants': [widget.myId, widget.peerId] 
    }, SetOptions(merge: true));
  }

  void _enviarMensaje() {
    final String text = _msgController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _msgController.clear();

    FirebaseFirestore.instance.collection('internal_chats').doc(chatId).collection('messages').add({
      'senderId': widget.myId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    FirebaseFirestore.instance.collection('internal_chats').doc(chatId).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [widget.myId, widget.peerId],
      'unreadCount_${widget.peerId}': FieldValue.increment(1)
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('internal_chats')
                    .doc(chatId).collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msgs = snapshot.data!.docs;

                  if (msgs.isEmpty) {
                    return Center(child: Text('Inicia la conversación con ${widget.peerName}.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final data = msgs[index].data() as Map<String, dynamic>;
                      final bool esMio = data['senderId'] == widget.myId;
                      final DateTime? fecha = (data['timestamp'] as Timestamp?)?.toDate();
                      final String hora = fecha != null ? DateFormat('HH:mm').format(fecha) : '...';

                      return Align(
                        alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: esMio ? Colors.cyan : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: esMio ? const Radius.circular(15) : Radius.zero,
                              bottomRight: esMio ? Radius.zero : const Radius.circular(15),
                            ),
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(data['text'], style: TextStyle(color: esMio ? Colors.white : Colors.black)),
                              const SizedBox(height: 4),
                              Text(hora, style: TextStyle(fontSize: 10, color: esMio ? Colors.white70 : Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _msgController, decoration: InputDecoration(hintText: 'Escribe un mensaje...', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)))),
                  const SizedBox(width: 8),
                  CircleAvatar(backgroundColor: Colors.cyan, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _enviarMensaje)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- PESTAÑA 2: GESTOR DE TAREAS ---
class _TaskManagerTab extends StatelessWidget {
  final String currentUserId;
  const _TaskManagerTab({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold( 
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            showDialog(context: context, builder: (_) => _CreateTaskDialog(creatorId: currentUserId));
          },
        ),
        body: Column(
          children: [
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.deepPurple,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Pendientes'), 
                Tab(text: 'Completadas'),
                Tab(text: 'Generadas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TaskList(filterField: 'assignedToId', myId: currentUserId, statusFilter: 'pending'),
                  _TaskList(filterField: 'assignedToId', myId: currentUserId, statusFilter: 'done'),
                  _TaskList(filterField: 'creatorId', myId: currentUserId, statusFilter: null),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final String filterField;
  final String myId;
  final String? statusFilter; 

  const _TaskList({required this.filterField, required this.myId, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('internal_tasks').where(filterField, isEqualTo: myId);
    
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    query = query.orderBy('dueDate'); 

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: SelectableText('⚠️ Error (Índice): ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data!.docs;
        
        if (docs.isEmpty) {
          String msg = '¡Todo limpio!';
          if (filterField == 'creatorId') {
            msg = 'No has asignado tareas aún';
          } else if (statusFilter == 'done') {
            msg = 'Sin tareas completadas';
          }
          return Center(child: Text(msg, style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final DateTime limite = (data['dueDate'] as Timestamp).toDate();
            
            final String status = data['status'] ?? 'pending';
            final bool esCompletada = status == 'done';
            final bool soyElCreador = filterField == 'creatorId';

            Color fechaColor = Colors.grey;
            if (!esCompletada && limite.difference(DateTime.now()).inDays < 2) fechaColor = Colors.red;

            return Card(
              color: esCompletada ? Colors.green.shade50 : Colors.white,
              child: ListTile(
                leading: soyElCreador 
                  ? Tooltip(
                      message: esCompletada ? 'Completada por compañero' : 'Pendiente',
                      child: CircleAvatar(
                        backgroundColor: esCompletada ? Colors.green : Colors.orange,
                        radius: 15,
                        child: Icon(esCompletada ? Icons.check : Icons.access_time, color: Colors.white, size: 16),
                      ),
                    )
                  : Checkbox(
                      value: esCompletada,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        FirebaseFirestore.instance.collection('internal_tasks').doc(docs[index].id).update({'status': val == true ? 'done' : 'pending'});
                      },
                    ),
                title: Text(data['title'], style: TextStyle(decoration: esCompletada ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    data['description'] != null 
                        ? Text(data['description'], maxLines: 2, overflow: TextOverflow.ellipsis)
                        : const SizedBox.shrink(),
                        
                    const SizedBox(height: 5),
                    Row(children: [
                      Icon(Icons.calendar_today, size: 12, color: fechaColor),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd/MM/yyyy').format(limite), style: TextStyle(color: fechaColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // FIX: Flexible para evitar overflow en nombres largos
                      Flexible(
                        child: Text(
                          soyElCreador ? "Para: ${data['assignedToName'] ?? 'Desconocido'}" : "De: ${data['creatorName'] ?? 'Admin'}",
                          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.deepPurple),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ]),
                ]),
                trailing: (esCompletada || soyElCreador) ? IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: () => FirebaseFirestore.instance.collection('internal_tasks').doc(docs[index].id).delete()) : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _CreateTaskDialog extends StatefulWidget {
  final String creatorId;
  
  const _CreateTaskDialog({
    required this.creatorId,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedStaffId;
  String? _selectedStaffName;
  List<Map<String, dynamic>> _staffList = [];

  @override 
  void initState() { 
    super.initState(); 
    _loadStaff(); 
  }

  Future<void> _loadStaff() async {
    final snap = await FirebaseFirestore.instance.collection('users').where('rol', whereIn: ['admin', 'profesional', 'administrador']).get();
    if (!mounted) return;
    setState(() {
      _staffList = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': (data['nombreCompleto'] ?? data['nombre'] ?? 'Staff').toString()
        };
      }).toList();
    });
  }

  @override 
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Tarea'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Asignar a', 
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStaffId,
                  isDense: true,
                  hint: const Text('Seleccionar...'),
                  items: _staffList.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name']))).toList(), 
                  onChanged: (val) { 
                    setState(() { 
                      _selectedStaffId = val; 
                      _selectedStaffName = _staffList.firstWhere((s) => s['id'] == val)['name']; 
                    }); 
                  }
                ),
              ),
            ),
            const SizedBox(height: 10), 
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título Tarea', border: OutlineInputBorder())), 
            const SizedBox(height: 10), 
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())), 
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero, 
              title: const Text('Fecha Límite:'), 
              trailing: TextButton.icon(
                icon: const Icon(Icons.calendar_month), 
                label: Text(DateFormat('dd/MM').format(_selectedDate)), 
                onPressed: () async { 
                  final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030)); 
                  if (d != null) setState(() => _selectedDate = d); 
                }
              )
            )
          ]
        )
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (_selectedStaffId == null || _titleController.text.isEmpty) {
              return;
            }
            
            String myName = 'Admin'; 
            final myDoc = await FirebaseFirestore.instance.collection('users').doc(widget.creatorId).get(); 
            if(myDoc.exists) {
              myName = myDoc.data()?['nombreCompleto'] ?? 'Compañero';
            }
            
            await FirebaseFirestore.instance.collection('internal_tasks').add({
              'title': _titleController.text.trim(), 
              'description': _descController.text.trim(), 
              'assignedToId': _selectedStaffId, 
              'assignedToName': _selectedStaffName, 
              'creatorId': widget.creatorId, 
              'creatorName': myName, 
              'dueDate': Timestamp.fromDate(_selectedDate), 
              'status': 'pending', 
              'createdAt': FieldValue.serverTimestamp()
            });
            
            if (!context.mounted) {
              return;
            }
            Navigator.pop(context);
          }, 
          child: const Text('ASIGNAR')
        )
      ],
    );
  }
}