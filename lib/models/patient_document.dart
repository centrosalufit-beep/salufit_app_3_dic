import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDocument {
  final String id;
  final String titulo;
  final String tipo;
  final String urlPdf;
  final bool firmado;
  final DateTime? fechaFirma;

  PatientDocument({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.urlPdf,
    required this.firmado,
    this.fechaFirma,
  });

  factory PatientDocument.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    DateTime? fecha;
    if (data['fechaFirma'] != null) {
      fecha = (data['fechaFirma'] as Timestamp).toDate();
    }

    return PatientDocument(
      id: doc.id,
      titulo: data['titulo'] ?? 'Documento sin título',
      tipo: data['tipo'] ?? 'General',
      urlPdf: data['urlPdf'] ?? '',
      firmado: data['firmado'] ?? false,
      fechaFirma: fecha,
    );
  }
}