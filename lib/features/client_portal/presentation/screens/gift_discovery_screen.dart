import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/home_providers.dart';

class GiftDiscoveryScreen extends ConsumerWidget {
  const GiftDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // ADN 2026: Usamos métodos, no asignaciones directas
            ref.read(homeTabProvider.notifier).setTab(0);
          },
          child: const Text('Volver a Inicio'),
        ),
      ),
    );
  }
}
