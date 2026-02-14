import 'package:flutter_riverpod/flutter_riverpod.dart';

// Este provider controla si ya se mostró el aviso en la sesión actual
final hasShownSignatureAlertProvider = StateProvider<bool>((ref) => false);
