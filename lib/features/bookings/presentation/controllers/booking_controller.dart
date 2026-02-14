import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/bookings/data/class_repository.dart';

class BookingController extends StateNotifier<AsyncValue<void>> {
  BookingController(this._repository) : super(const AsyncValue.data(null));

  final ClassRepository _repository;

  Future<void> createBooking({
    required String classId,
    required String userId,
    required String userEmail,
    required String userName,
    required DateTime date,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.inscribirUsuario(
        classId: classId,
        userId: userId,
        userEmail: userEmail,
      ),
    );
  }
}

final bookingControllerProvider =
    StateNotifierProvider<BookingController, AsyncValue<void>>((ref) {
  final repository = ref.watch(classRepositoryProvider);
  return BookingController(repository);
});
