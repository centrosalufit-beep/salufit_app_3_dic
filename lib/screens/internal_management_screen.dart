import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InternalManagementScreen extends StatelessWidget {
  final String currentUserId;
  final String viewType; // 'chat' o 'tasks'
  
  const InternalManagementScreen({
    super.key, 
    required this.currentUserId,
    required this.viewType, 
  });

  @override
  Widget build(BuildContext context) {
    final bool isChat = viewType == 'chat';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isChat ? "Chats de Equipo" : "Gestión de Tareas", 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: isChat ? Colors.cyan : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isChat 
          ? _StaffDirectoryTab(currentUserId: currentUserId)
          : _TaskManagerTab(currentUserId: currentUserId),
    );
  }
}

// --- PESTAÑA 1: DIRECTORIO DE STAFF ---
class _StaffDirectoryTab extends StatelessWidget {
  final String currentUserId;
  const _StaffDirectoryTab({required this.currentUserId});

  String _getChatId(String peerId) {
    return currentUserId.compareTo(peerId) < 0 
        ? '${currentUserId}_$peerId' 
        : '${peerId}_$currentUserId';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('rol', whereIn: ['admin', 'profesional', 'administrador']) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs.where((d) => d.id != currentUserId).toList(); 

        return ListView.separated(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String nombre = data['nombreCompleto'] ?? data['nombre'] ?? "Compañero";
            String rol = (data['rol'] ?? "Staff").toString().toUpperCase();
            String staffId = docs[index].id;
            String chatId = _getChatId(staffId);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.cyan.shade50,
                    child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : "?", style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('internal_chats').doc(chatId).snapshots(),
                        builder: (context, chatSnap) {
                          if (chatSnap.hasData && chatSnap.data!.exists) {
                            var chatData = chatSnap.data!.data() as Map<String, dynamic>;
                            int unread = (chatData['unreadCount_$currentUserId'] as num? ?? 0).toInt();
                            if (unread > 0) {
                              return Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                child: Text("$unread", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              );
                            }
                          }
                          return const SizedBox();
                        },
                      )
                    ],
                  ),
                  subtitle: Text(rol, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: IconButton(
                    tooltip: "Abrir Chat",
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.cyan),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => _ChatScreen(myId: currentUserId, peerId: staffId, peerName: nombre)));
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- PANTALLA DE CHAT ---
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
    String text = _msgController.text.trim();
    if (text.isEmpty) return;
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
    DateTime fechaCorte = DateTime.now().subtract(const Duration(days: 30));

    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('internal_chats')
                  .doc(chatId).collection('messages')
                  .where('timestamp', isGreaterThan: fechaCorte) 
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var msgs = snapshot.data!.docs;

                if (msgs.isEmpty) {
                  return Center(child: Text("Inicia la conversación con ${widget.peerName}.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    var data = msgs[index].data() as Map<String, dynamic>;
                    bool esMio = data['senderId'] == widget.myId;
                    DateTime? fecha = (data['timestamp'] as Timestamp?)?.toDate();
                    String hora = fecha != null ? DateFormat('HH:mm').format(fecha) : "...";

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
                Expanded(child: TextField(controller: _msgController, decoration: InputDecoration(hintText: "Escribe un mensaje...", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)))),
                const SizedBox(width: 8),
                CircleAvatar(backgroundColor: Colors.cyan, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _enviarMensaje)),
              ],
            ),
          )
        ],
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
      length: 2,
      child: Scaffold( // Scaffold interno para tener FAB
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            // Diálogo para CREAR tarea nueva
            showDialog(context: context, builder: (_) => _CreateTaskDialog(creatorId: currentUserId));
          },
        ),
        body: Column(
          children: [
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.deepPurple,
              tabs: [Tab(text: "Mis Pendientes"), Tab(text: "Completadas")],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TaskList(filterField: 'assignedToId', myId: currentUserId, statusFilter: 'pending'),
                  _TaskList(filterField: 'assignedToId', myId: currentUserId, statusFilter: 'done'),
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
  final String statusFilter; 

  const _TaskList({required this.filterField, required this.myId, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('internal_tasks')
          .where(filterField, isEqualTo: myId)
          .where('status', isEqualTo: statusFilter) 
          .orderBy('dueDate') 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: SelectableText("⚠️ Error (Índice): ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center)));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text(statusFilter == 'pending' ? "¡Todo al día!" : "Sin tareas completadas", style: const TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            DateTime limite = (data['dueDate'] as Timestamp).toDate();
            bool esCompletada = statusFilter == 'done';
            
            Color fechaColor = Colors.grey;
            if (!esCompletada && limite.difference(DateTime.now()).inDays < 2) fechaColor = Colors.red;

            return Card(
              color: esCompletada ? Colors.green.shade50 : Colors.white,
              child: ListTile(
                leading: Checkbox(
                  value: esCompletada,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection('internal_tasks').doc(docs[index].id).update({'status': val == true ? 'done' : 'pending'});
                  },
                ),
                title: Text(data['title'], style: TextStyle(decoration: esCompletada ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if(data['description'] != null) Text(data['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(children: [Icon(Icons.calendar_today, size: 12, color: fechaColor), const SizedBox(width: 4), Text(DateFormat('dd/MM/yyyy').format(limite), style: TextStyle(color: fechaColor, fontSize: 12, fontWeight: FontWeight.bold)), const Spacer(), Text("De: ${data['creatorName'] ?? 'Admin'}", style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.deepPurple))]),
                ]),
                trailing: esCompletada ? IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: () => FirebaseFirestore.instance.collection('internal_tasks').doc(docs[index].id).delete()) : null,
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
  final String? preSelectedStaffId;
  final String? preSelectedStaffName;
  
  const _CreateTaskDialog({required this.creatorId, this.preSelectedStaffId, this.preSelectedStaffName});

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
    _selectedStaffId = widget.preSelectedStaffId; 
    _selectedStaffName = widget.preSelectedStaffName; 
    _loadStaff(); 
  }

  Future<void> _loadStaff() async {
    // Cargamos usuarios que sean admin o profesional para asignarles tareas
    var snap = await FirebaseFirestore.instance.collection('users').where('rol', whereIn: ['admin', 'profesional', 'administrador']).get();
    setState(() {
      _staffList = snap.docs.map((d) {
        var data = d.data();
        return {
          'id': d.id,
          'name': (data['nombreCompleto'] ?? data['nombre'] ?? "Staff").toString()
        };
      }).toList();
    });
  }

  @override 
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nueva Tarea"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStaffId, 
              decoration: const InputDecoration(labelText: "Asignar a", border: OutlineInputBorder()), 
              items: _staffList.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name']))).toList(), 
              onChanged: (val) { 
                setState(() { 
                  _selectedStaffId = val; 
                  _selectedStaffName = _staffList.firstWhere((s) => s['id'] == val)['name']; 
                }); 
              }
            ),
            const SizedBox(height: 10), 
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Título Tarea", border: OutlineInputBorder())), 
            const SizedBox(height: 10), 
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder())), 
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero, 
              title: const Text("Fecha Límite:"), 
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () async {
            if (_selectedStaffId == null || _titleController.text.isEmpty) return;
            
            String myName = "Admin"; 
            var myDoc = await FirebaseFirestore.instance.collection('users').doc(widget.creatorId).get(); 
            if(myDoc.exists) myName = myDoc.data()?['nombreCompleto'] ?? "Compañero";
            
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
            if(mounted) Navigator.pop(context);
          }, 
          child: const Text("ASIGNAR")
        )
      ],
    );
  }
}