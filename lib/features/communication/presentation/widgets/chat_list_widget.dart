import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/features/communication/presentation/chat_detail_screen.dart';

class ChatListWidget extends StatelessWidget {
  const ChatListWidget({required this.currentUserId, this.isStaffOnly = false, super.key});
  final String currentUserId; final bool isStaffOnly;

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('users_app');
    final query = isStaffOnly 
        ? q.where('role', whereIn: const ['admin', 'profesional', 'administrador']) 
        : q;

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();
        return ListView.separated(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          separatorBuilder: (c, i) => const Divider(color: Colors.white12),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>? ?? {};
            final name = (data['name'] as String?) ?? 'Miembro';
            final role = (data['role'] as String? ?? 'Staff').toUpperCase();
            final isAdmin = role.contains('ADMIN');
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isAdmin ? Colors.orange : Colors.teal, 
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
              ),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                isAdmin ? 'ADMINISTRACIÓN' : 'PROFESIONAL', 
                style: TextStyle(color: isAdmin ? Colors.orange : Colors.tealAccent, fontSize: 10)
              ),
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute<void>(
                  builder: (_) => ChatDetailScreen(
                    currentUserId: currentUserId, 
                    otherUserId: docs[i].id, 
                    otherUserName: name
                  )
                )
              ),
            );
          },
        );
      },
    );
  }
}
