import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(homeTabProvider);
    final selectedDate = ref.watch(bookingDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Salufit Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tab Activa: $tabIndex'),
            Text('Fecha: ${selectedDate.toLocal()}'),
            ElevatedButton(
              onPressed: () => ref.read(homeTabProvider.notifier).setTab(0),
              child: const Text('Reset Tab'),
            ),
          ],
        ),
      ),
    );
  }
}
