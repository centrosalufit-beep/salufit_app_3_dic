import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDocument {
  const PatientDocument({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.urlPdf,
    required this.firmado,
    this.fechaFirma,
  });

  factory PatientDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    DateTime? fecha;
    if (data['fechaFirma'] != null) {
      // Zero-Dynamic: Casting explícito de Timestamp
      fecha = (data['fechaFirma'] as Timestamp).toDate();
    }

    return PatientDocument(
      id: doc.id,
      // Zero-Dynamic: Casting explícito
      titulo: (data['titulo'] as String?) ?? 'Documento sin título',
      tipo: (data['tipo'] as String?) ?? 'General',
      urlPdf: (data['urlPdf'] as String?) ?? '',
      firmado: (data['firmado'] as bool?) ?? false,
      fechaFirma: fecha,
    );
  }

  final String id;
  final String titulo;
  final String tipo;
  final String urlPdf;
  final bool firmado;
  final DateTime? fechaFirma;
}
