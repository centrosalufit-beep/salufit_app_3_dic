import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({required this.currentUserId, required this.otherUserId, required this.otherUserName, super.key});
  final String currentUserId; final String otherUserId; final String otherUserName;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Chat con $otherUserName')),
      body: const Center(child: Text('Buzón de mensajes activo', style: TextStyle(color: Colors.white70))),
    );
  }
}
