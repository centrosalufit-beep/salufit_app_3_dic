import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/features/auth/data/auth_repository.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() => null;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => 
        ref.read(authRepositoryProvider).signIn(email, password));
  }
}
