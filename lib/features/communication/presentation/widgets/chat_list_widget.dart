import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/communication/presentation/chat_detail_screen.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';

class ChatListWidget extends StatelessWidget {
  const ChatListWidget({
    required this.currentUserId,
    this.isStaffOnly = false,
    super.key,
  });
  final String currentUserId;
  final bool isStaffOnly;

  String _chatId(String otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final q = FirebaseFirestore.instance.collection('users_app');
    final query = isStaffOnly
        ? q.where(
            'rol',
            whereIn: const ['admin', 'profesional', 'administrador'],
          )
        : q;

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .toList();
        return ListView.separated(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          separatorBuilder: (c, i) => const Divider(color: Colors.white12),
          itemBuilder: (context, i) {
            final data = docs[i].data()! as Map<String, dynamic>;
            final nombre = data.safeString('nombreCompleto').isNotEmpty
                ? data.safeString('nombreCompleto')
                : data.safeString('nombre').isNotEmpty
                    ? data.safeString('nombre')
                    : t.chatMemberDefault;
            final rol =
                data.safeString('rol', defaultValue: 'staff').toUpperCase();
            final isAdmin = rol.contains('ADMIN');
            final chatId = _chatId(docs[i].id);

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .snapshots(),
              builder: (context, chatSnap) {
                var lastMsg = '';
                var hasUnread = false;

                if (chatSnap.hasData && chatSnap.data!.exists) {
                  final chatData =
                      chatSnap.data!.data()! as Map<String, dynamic>;
                  lastMsg = chatData.safeString('lastMessage');
                  final lastMsgTime =
                      (chatData['lastMessageTime'] as Timestamp?)?.toDate();
                  final lastRead =
                      (chatData['lastReadBy_$currentUserId'] as Timestamp?)
                          ?.toDate();
                  final lastSender = chatData.safeString('lastMessageSenderId');

                  // Unread si el último mensaje no es mío y no lo he leído
                  if (lastMsgTime != null && lastSender != currentUserId) {
                    hasUnread =
                        lastRead == null || lastMsgTime.isAfter(lastRead);
                  }
                }

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            isAdmin ? Colors.orange : Colors.teal,
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1E293B),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    nombre,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin ? t.chatRoleAdminUpper : t.chatRoleProfessionalUpper,
                        style: TextStyle(
                          color: isAdmin ? Colors.orange : Colors.tealAccent,
                          fontSize: 10,
                        ),
                      ),
                      if (lastMsg.isNotEmpty)
                        Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.white70
                                : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChatDetailScreen(
                        currentUserId: currentUserId,
                        otherUserId: docs[i].id,
                        otherUserName: nombre,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
