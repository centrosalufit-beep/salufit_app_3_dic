import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class InternalManagementScreen extends StatelessWidget {
  const InternalManagementScreen({
    required this.currentUserId,
    required this.userRole,
    required this.viewType,
    super.key,
  });

  final String currentUserId;
  final String userRole;
  final String viewType;

  @override
  Widget build(BuildContext context) {
    final isChat = viewType.toLowerCase() == 'chat';
    final isAdmin = userRole == 'admin' || userRole == 'administrador';

    if (isChat) {
      return DefaultTabController(
        length: isAdmin ? 2 : 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Comunicación Equipo'),
            backgroundColor: Colors.cyan.shade800,
            foregroundColor: Colors.white,
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: <Widget>[
                const Tab(text: 'CHATS EQUIPO'),
                if (isAdmin) const Tab(text: 'DIFUSIÓN ADMIN'),
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              _StaffDirectoryTab(
                currentUserId: currentUserId,
                userRole: userRole,
              ),
              if (isAdmin) _BroadcastSelectorTab(currentUserId: currentUserId),
            ],
          ),
        ),
      );
    } else {
      return _TaskManagerTab(currentUserId: currentUserId);
    }
  }
}

class _StaffDirectoryTab extends StatelessWidget {
  const _StaffDirectoryTab({
    required this.currentUserId,
    required this.userRole,
  });

  final String currentUserId;
  final String userRole;

  String _getChatId(String peerId) => currentUserId.compareTo(peerId) < 0
      ? '${currentUserId}_$peerId'
      : '${peerId}_$currentUserId';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where(
        'rol',
        whereIn: <String>[
          'admin',
          'profesional',
          'administrador',
          'staff',
          'fisioterapeuta',
          'entrenador',
          'nutricionista',
        ],
      ).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawDocs =
            snapshot.data!.docs.where((d) => d.id != currentUserId).toList();

        final uniqueStaffMap = <String, QueryDocumentSnapshot>{};
        for (final doc in rawDocs) {
          uniqueStaffMap[doc.id] = doc;
        }
        final staffList = uniqueStaffMap.values.toList();

        if (staffList.isEmpty) {
          return const Center(
            child: Text('No hay otros compañeros disponibles.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: staffList.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = staffList[index].data() as Map<String, dynamic>?;
            final nombre = data.safeString(
              'nombreCompleto',
              defaultValue:
                  data.safeString('nombre', defaultValue: 'Compañero'),
            );
            final chatId = _getChatId(staffList[index].id);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.cyan.withValues(alpha: 0.1),
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('internal_chats')
                      .doc(chatId)
                      .snapshots(),
                  builder: (c, s) {
                    if (!s.hasData || !s.data!.exists) {
                      return const Text(
                        'Sin mensajes aún',
                        style: TextStyle(fontSize: 11),
                      );
                    }
                    final chatData = s.data!.data() as Map<String, dynamic>?;
                    return Text(
                      chatData.safeString('lastMessage', defaultValue: '...'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    );
                  },
                ),
                trailing: const Icon(Icons.chat_bubble_outline, size: 18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => _ChatScreen(
                      myId: currentUserId,
                      peerId: staffList[index].id,
                      peerName: nombre,
                    ),
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

class _ChatScreen extends StatefulWidget {
  const _ChatScreen({
    required this.myId,
    required this.peerId,
    required this.peerName,
  });

  final String myId;
  final String peerId;
  final String peerName;

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  String get chatId => widget.myId.compareTo(widget.peerId) < 0
      ? '${widget.myId}_${widget.peerId}'
      : '${widget.peerId}_${widget.myId}';

  Future<void> _send() async {
    final txt = _msgController.text.trim();
    if (txt.isEmpty) {
      return;
    }
    _msgController.clear();

    final chatRef =
        FirebaseFirestore.instance.collection('internal_chats').doc(chatId);
    final batch = FirebaseFirestore.instance.batch()
      ..set(chatRef.collection('messages').doc(), {
        'senderId': widget.myId,
        'text': txt,
        'timestamp': FieldValue.serverTimestamp(),
      })
      ..set(
        chatRef,
        {
          'lastMessage': txt,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'participants': [widget.myId, widget.peerId],
        },
        SetOptions(merge: true),
      );

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('internal_chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (c, i) {
                    final d =
                        snap.data!.docs[i].data() as Map<String, dynamic>?;
                    final esMio = d.safeString('senderId') == widget.myId;
                    return Align(
                      alignment:
                          esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: esMio ? Colors.cyan : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          d.safeString('text'),
                          style: TextStyle(
                            color: esMio ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyan),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastSelectorTab extends StatelessWidget {
  const _BroadcastSelectorTab({required this.currentUserId});
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _btn(
          context,
          'A PROFESIONALES',
          'Aparecerá a fisios y staff',
          Colors.orange,
          'profesional',
        ),
        const SizedBox(height: 15),
        _btn(
          context,
          'A CLIENTES',
          'Aviso para todos los pacientes',
          Colors.blue,
          'cliente',
        ),
      ],
    );
  }

  Widget _btn(
    BuildContext context,
    String t,
    String s,
    Color c,
    String target,
  ) {
    return Card(
      color: c.withValues(alpha: 0.1),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.campaign, color: c),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                _BroadcastEditor(userId: currentUserId, target: target),
          ),
        ),
      ),
    );
  }
}

class _BroadcastEditor extends StatefulWidget {
  const _BroadcastEditor({required this.userId, required this.target});
  final String userId;
  final String target;
  @override
  State<_BroadcastEditor> createState() => _BroadcastEditorState();
}

class _BroadcastEditorState extends State<_BroadcastEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Difusión: ${widget.target.toUpperCase()}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Mensaje masivo...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_controller.text.isEmpty) {
                    return;
                  }

                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  await FirebaseFirestore.instance
                      .collection('broadcasts')
                      .add({
                    'senderId': widget.userId,
                    'text': _controller.text.trim(),
                    'targetAudience': widget.target,
                    'timestamp': FieldValue.serverTimestamp(),
                    'isActive': true,
                  });

                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Difusión enviada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('ENVIAR DIFUSIÓN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskManagerTab extends StatelessWidget {
  const _TaskManagerTab({required this.currentUserId});
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: const Text('Gestor tareas'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'PENDIENTES'),
              Tab(text: 'COMPLETADAS'),
              Tab(text: 'GENERADAS'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => _CreateTaskDialog(creatorId: currentUserId),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: TabBarView(
          children: [
            _TaskList(
              filterField: 'assignedToId',
              myId: currentUserId,
              status: 'pending',
            ),
            _TaskList(
              filterField: 'assignedToId',
              myId: currentUserId,
              status: 'done',
            ),
            _TaskList(
              filterField: 'creatorId',
              myId: currentUserId,
              status: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.filterField,
    required this.myId,
    required this.status,
  });
  final String filterField;
  final String myId;
  final String? status;

  @override
  Widget build(BuildContext context) {
    var q = FirebaseFirestore.instance
        .collection('internal_tasks')
        .where(filterField, isEqualTo: myId);
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: q.orderBy('dueDate').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Sin tareas aquí.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>?;
            final esCompletada = data.safeString('status') == 'done';
            return Card(
              color: esCompletada ? Colors.green.shade50 : Colors.white,
              child: ListTile(
                leading: Checkbox(
                  value: esCompletada,
                  onChanged: (v) {
                    docs[i]
                        .reference
                        .update({'status': v! ? 'done' : 'pending'});
                  },
                ),
                title: Text(
                  data.safeString('title'),
                  style: TextStyle(
                    decoration:
                        esCompletada ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Límite: ${DateFormat('dd/MM/yy').format(data.safeDateTime('dueDate'))}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    docs[i].reference.delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog({required this.creatorId});
  final String creatorId;
  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final TextEditingController _title = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _staffId;
  String? _staffName;
  List<Map<String, String>> _list = [];
  bool _loadingStaff = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await FirebaseFirestore.instance
        .collection('users')
        .where('rol', whereIn: ['admin', 'profesional', 'staff']).get();
    if (!mounted) {
      return;
    }
    final uniqueStaff = <String, String>{};
    for (final d in s.docs) {
      final data = d.data();
      final name = data.safeString(
        'nombreCompleto',
        defaultValue: data.safeString('nombre', defaultValue: 'Staff'),
      );
      uniqueStaff[d.id] = name;
    }
    setState(() {
      _list = uniqueStaff.entries
          .map((e) => {'id': e.key, 'name': e.value})
          .toList();
      _loadingStaff = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Tarea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loadingStaff)
            const CircularProgressIndicator()
          else
            DropdownButtonFormField<String>(
              initialValue: _staffId,
              items: _list
                  .map(
                    (s) => DropdownMenuItem(
                      value: s['id'],
                      child: Text(s['name']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _staffId = v;
                _staffName = _list.firstWhere((e) => e['id'] == v)['name'];
              }),
              decoration: const InputDecoration(labelText: 'Asignar a...'),
            ),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          ListTile(
            title: const Text('Fecha Límite'),
            trailing: TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (d != null) {
                  setState(() => _date = d);
                }
              },
              child: Text(DateFormat('dd/MM').format(_date)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_staffId == null || _title.text.isEmpty) {
              return;
            }

            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            await FirebaseFirestore.instance.collection('internal_tasks').add({
              'title': _title.text.trim(),
              'assignedToId': _staffId,
              'assignedToName': _staffName,
              'creatorId': widget.creatorId,
              'status': 'pending',
              'dueDate': Timestamp.fromDate(_date),
              'createdAt': FieldValue.serverTimestamp(),
            });

            if (!mounted) {
              return;
            }
            navigator.pop();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Tarea asignada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text('ASIGNAR'),
        ),
      ],
    );
  }
}
