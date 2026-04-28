import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/whatsapp_bot/application/whatsapp_bot_providers.dart';

class ImportExcelButton extends ConsumerStatefulWidget {
  const ImportExcelButton({super.key});

  @override
  ConsumerState<ImportExcelButton> createState() => _ImportExcelButtonState();
}

class _ImportExcelButtonState extends ConsumerState<ImportExcelButton> {
  bool _processing = false;

  Future<void> _pickAndImport() async {
    setState(() => _processing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo')),
        );
        return;
      }
      final base64Str = base64Encode(bytes);
      final import = await ref.read(
        importClinniExcelProvider(
          fileBase64: base64Str,
          fileName: file.name,
        ).future,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                import.errors > 0 ? Icons.warning_amber : Icons.check_circle,
                color: import.errors > 0 ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('Importación Clinni'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Importadas: ${import.imported}'),
              Text('Duplicadas (ignoradas): ${import.duplicates}'),
              Text('Errores: ${import.errors}'),
              if (import.errorMessages.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Detalles de errores:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Text(
                      import.errorMessages.join('\n'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _processing ? null : _pickAndImport,
      icon: _processing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file),
      label: Text(_processing ? 'Importando…' : 'Importar citas Clinni'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
