import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/features/auth/data/auth_repository.dart';

// Este archivo se generará automáticamente después
part 'activation_provider.g.dart';

@riverpod
class ActivationController extends _$ActivationController {
  @override
  FutureOr<void> build() {
    // Estado inicial vacío (idle)
  }

  Future<void> requestCode(String userId) async {
    state = const AsyncLoading();
    // AsyncValue.guard espera una función asíncrona explícita
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).sendOTP(userId);
    });
  }

  Future<void> submitActivation(String userId, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).activateAccount(
            userId: userId,
            code: code,
          );
    });
  }
}
