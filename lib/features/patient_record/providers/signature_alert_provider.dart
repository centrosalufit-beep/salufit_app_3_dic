import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signature_alert_provider.g.dart';

@riverpod
class SignatureAlert extends _$SignatureAlert {
  @override
  bool build() => false;

  void showAlert() => state = true;
  void hideAlert() => state = false;
}
