import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'booking_controller.g.dart';

@riverpod
class BookingController extends _$BookingController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createBooking(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Implementación pendiente
    });
  }
}
