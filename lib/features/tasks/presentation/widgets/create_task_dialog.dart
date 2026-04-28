import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/tasks/application/task_providers.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  const CreateTaskDialog({
    required this.currentUserId,
    required this.currentUserName,
    super.key,
  });

  final String currentUserId;
  final String currentUserName;

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _fechaLimite;
  final Set<String> _selectedUids = {};
  List<_StaffUser> _staffList = const [];
  bool _loadingStaff = true;
  bool _submitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final snap = await ref
          .read(firebaseFirestoreProvider)
          .collection('users_app')
          .where('role', whereIn: ['admin', 'profesional', 'administrador'])
          .get();
      final list = snap.docs
          .where((d) => d.id != widget.currentUserId)
          .map((d) {
            final data = d.data();
            final full = (data['nombreCompleto'] as String?) ?? '';
            final nombre = (data['nombre'] as String?) ?? '';
            final apellidos = (data['apellidos'] as String?) ?? '';
            final combined = full.isNotEmpty
                ? full
                : '$nombre $apellidos'.trim();
            final display = combined.isNotEmpty
                ? combined
                : (data['email'] as String?) ?? d.id;
            return _StaffUser(uid: d.id, nombre: display);
          })
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      if (!mounted) return;
      setState(() {
        _staffList = list;
        _loadingStaff = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStaff = false;
        _errorMsg = 'No se pudo cargar el listado de staff: $e';
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _fechaLimite = picked);
  }

  bool get _canSubmit =>
      _tituloCtrl.text.trim().isNotEmpty &&
      _fechaLimite != null &&
      _selectedUids.isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });
    try {
      final destinatarios = _staffList
          .where((u) => _selectedUids.contains(u.uid))
          .map((u) => (uid: u.uid, nombre: u.nombre))
          .toList();
      await ref.read(taskRepositoryProvider).createTasks(
            titulo: _tituloCtrl.text,
            descripcion: _descCtrl.text,
            fechaLimite: _fechaLimite!,
            asignadorUid: widget.currentUserId,
            asignadorNombre: widget.currentUserName,
            destinatarios: destinatarios,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            '${destinatarios.length} '
            '${destinatarios.length == 1 ? 'tarea asignada' : 'tareas asignadas'}',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMsg = 'Error: ${e.message ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMsg = 'Error inesperado: $e';
      });
    }
  }

  String _fmtDate(DateTime d) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Nueva tarea',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event, size: 20, color: Color(0xFF009688)),
                  const SizedBox(width: 8),
                  const Text(
                    'Fecha límite *:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _fechaLimite == null
                          ? 'Sin fecha seleccionada'
                          : _fmtDate(_fechaLimite!),
                      style: TextStyle(
                        color: _fechaLimite == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Elegir fecha'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Destinatarios *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_loadingStaff)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_staffList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay otros miembros del staff disponibles.'),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: _staffList.map((u) {
                      final selected = _selectedUids.contains(u.uid);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(u.nombre),
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (v ?? false) {
                              _selectedUids.add(u.uid);
                            } else {
                              _selectedUids.remove(u.uid);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              if (_selectedUids.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_selectedUids.length} destinatario${_selectedUids.length == 1 ? '' : 's'} seleccionado${_selectedUids.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF009688),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: const Text('ASIGNAR'),
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

class _StaffUser {
  const _StaffUser({required this.uid, required this.nombre});
  final String uid;
  final String nombre;
}
