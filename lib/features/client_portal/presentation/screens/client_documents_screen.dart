import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/sign_document_screen.dart';
import 'package:salufit_app/shared/widgets/salufit_header.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ClientDocumentsScreen extends StatefulWidget {
  const ClientDocumentsScreen({
    required this.userId,
    this.embedMode = false,
    super.key,
  });

  final String userId;
  final bool embedMode;

  @override
  State<ClientDocumentsScreen> createState() => _ClientDocumentsScreenState();
}

class _ClientDocumentsScreenState extends State<ClientDocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SalufitHeader(title: 'MI EXPEDIENTE'),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'PENDIENTES'),
                Tab(text: 'FIRMADOS'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DocumentList(userId: widget.userId, firmado: false),
                  _DocumentList(userId: widget.userId, firmado: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({required this.userId, required this.firmado});

  final String userId;
  final bool firmado;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = (snapshot.data?.docs ?? []).where((d) {
          final data = d.data()! as Map<String, dynamic>;
          return data['firmado'] == firmado;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  firmado ? Icons.check_circle_outline : Icons.pending_actions,
                  size: 50,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  firmado ? 'No hay documentos firmados' : 'No tienes documentos pendientes',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data()! as Map<String, dynamic>;
            final titulo = data.safeString('titulo');
            final tipo = data.safeString('tipo');
            final urlPdf = data.safeString('urlPdf');
            final fechaCreacion = (data['fechaCreacion'] as Timestamp?)?.toDate();
            final fechaFirma = (data['fechaFirma'] as Timestamp?)?.toDate();

            final isLegal = tipo == 'Legal';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: firmado
                      ? Colors.green.shade200
                      : (isLegal ? Colors.orange.shade200 : Colors.grey.shade200),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: firmado
                        ? Colors.green.shade50
                        : (isLegal ? Colors.orange.shade50 : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    firmado ? Icons.verified : (isLegal ? Icons.gavel : Icons.description),
                    color: firmado ? Colors.green : (isLegal ? Colors.orange : Colors.blue),
                  ),
                ),
                title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fechaCreacion != null)
                      Text('Asignado: ${DateFormat('dd/MM/yyyy').format(fechaCreacion)}', style: const TextStyle(fontSize: 11)),
                    if (firmado && fechaFirma != null)
                      Text('Firmado: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaFirma)}', style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: firmado ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        firmado ? 'FIRMADO' : (isLegal ? 'PENDIENTE DE FIRMA' : tipo.toUpperCase()),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: firmado ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: !firmado && isLegal
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<bool>(
                              builder: (_) => SignDocumentScreen(
                                documentId: doc.id,
                                documentTitle: titulo,
                                pdfUrl: urlPdf,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('FIRMAR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    : firmado
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
              ),
            );
          },
        );
      },
    );
  }
}
