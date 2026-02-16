import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminPatientDetailScreen extends StatefulWidget {
  const AdminPatientDetailScreen({
    required this.userId,
    required this.userName,
    required this.viewerRole,
    super.key,
  });
  final String userId;
  final String userName;
  final String viewerRole;

  @override
  State<AdminPatientDetailScreen> createState() =>
      _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends State<AdminPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _registrarAcceso();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _registrarAcceso() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid != widget.userId) {
        await FirebaseFirestore.instance
            .collection('audit_logs')
            .add(<String, dynamic>{
          'tipo': 'ACCESO_FICHA',
          'pacienteId': widget.userId,
          'pacienteNombre': widget.userName,
          'profesionalId': currentUser.uid,
          'profesionalEmail': currentUser.email,
          'fecha': FieldValue.serverTimestamp(),
          'detalles': 'Apertura de ficha completa',
        });
      }
    } on Exception catch (e) {
      if (kDebugMode) print('Error auditoría: $e');
    }
  }

  // REPARADO: Ahora se usa en las listas de abajo
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Pendiente';
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }
    return 'Sin fecha';
  }

  Future<void> _subirDocClinico() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final file = result.files.first;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('documentos_pacientes/${widget.userId}/${file.name}');
        await storageRef.putFile(File(file.path!));
        final downloadUrl = await storageRef.getDownloadURL();

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
        final userEmail = userDoc.data().safeString('email');

        await FirebaseFirestore.instance
            .collection('documents')
            .add(<String, dynamic>{
          'userId': widget.userId,
          'userEmail': userEmail,
          'titulo': file.name.replaceAll('.pdf', ''),
          'tipo': 'Clínico',
          'firmado': false,
          'urlPdf': downloadUrl,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _lanzarConsentimiento(String titulo, String urlPlantilla) async {
    setState(() => _isUploading = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final userEmail = userDoc.data().safeString('email');

      final docId = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('documents')
          .doc(docId)
          .set(<String, dynamic>{
        'id': docId,
        'userId': widget.userId,
        'userEmail': userEmail,
        'titulo': titulo,
        'tipo': 'Legal',
        'firmado': false,
        'urlPdf': urlPlantilla,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _mostrarMenuPrincipal() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMenuIconBtn(
                icon: Icons.fitness_center,
                color: Colors.blue,
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuIconBtn(
                icon: Icons.upload_file,
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _subirDocClinico();
                },
              ),
              _buildMenuIconBtn(
                icon: Icons.draw,
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _lanzarConsentimiento(
                    'Consentimiento Nuevo',
                    'https://ejemplo.com/doc.pdf',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'EJERCICIOS', icon: Icon(Icons.fitness_center)),
            Tab(text: 'CLÍNICOS', icon: Icon(Icons.folder_shared)),
            Tab(text: 'LEGALES', icon: Icon(Icons.gavel)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _mostrarMenuPrincipal,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListPlaceholder('Lista de Ejercicios'),
          _buildListPlaceholder('Documentos Clínicos'),
          _buildListPlaceholder('Documentos Legales'),
        ],
      ),
    );
  }

  Widget _buildListPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          const SizedBox(height: 10),
          Text(
            'Actualizado: ${_formatDate(Timestamp.now())}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
