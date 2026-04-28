import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/tasks/application/task_providers.dart';
import 'package:salufit_app/features/tasks/domain/task_model.dart';
import 'package:salufit_app/features/tasks/presentation/widgets/create_task_dialog.dart';
import 'package:salufit_app/features/tasks/presentation/widgets/task_card.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({
    required this.currentUserId,
    required this.currentUserName,
    super.key,
  });

  final String currentUserId;
  final String currentUserName;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => CreateTaskDialog(
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = (uid: widget.currentUserId, includeArchived: _showArchived);
    final received = ref.watch(receivedTasksProvider(args));
    final assigned = ref.watch(assignedTasksProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inbox), text: 'Mis tareas'),
            Tab(icon: Icon(Icons.send), text: 'Asignadas por mí'),
          ],
        ),
        actions: [
          Row(
            children: [
              const Text(
                'Ver histórico',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Switch(
                value: _showArchived,
                activeThumbColor: Colors.tealAccent,
                onChanged: (v) => setState(() => _showArchived = v),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add_task),
        label: const Text('Nueva tarea'),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _TaskList(
            asyncTasks: received,
            currentUserId: widget.currentUserId,
            isReceivedView: true,
            emptyMessage: _showArchived
                ? 'No hay tareas en el histórico'
                : 'No tienes tareas pendientes',
          ),
          _TaskList(
            asyncTasks: assigned,
            currentUserId: widget.currentUserId,
            isReceivedView: false,
            emptyMessage: _showArchived
                ? 'No hay tareas asignadas en el histórico'
                : 'No has asignado tareas pendientes',
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.asyncTasks,
    required this.currentUserId,
    required this.isReceivedView,
    required this.emptyMessage,
  });

  final AsyncValue<List<TaskModel>> asyncTasks;
  final String currentUserId;
  final bool isReceivedView;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return asyncTasks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error cargando tareas: $e',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.white38,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => TaskCard(
            task: tasks[i],
            currentUserId: currentUserId,
            isReceivedView: isReceivedView,
          ),
        );
      },
    );
  }
}
