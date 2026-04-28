import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/tasks/data/task_repository.dart';
import 'package:salufit_app/features/tasks/domain/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(firebaseFirestoreProvider));
});

typedef _TasksArgs = ({String uid, bool includeArchived});

final receivedTasksProvider =
    StreamProvider.family<List<TaskModel>, _TasksArgs>((ref, args) {
  return ref.watch(taskRepositoryProvider).watchReceivedTasks(
        uid: args.uid,
        includeArchived: args.includeArchived,
      );
});

final assignedTasksProvider =
    StreamProvider.family<List<TaskModel>, _TasksArgs>((ref, args) {
  return ref.watch(taskRepositoryProvider).watchAssignedTasks(
        uid: args.uid,
        includeArchived: args.includeArchived,
      );
});

final pendingTasksCountProvider =
    StreamProvider.family<int, String>((ref, uid) {
  return ref.watch(taskRepositoryProvider).watchPendingCount(uid);
});
