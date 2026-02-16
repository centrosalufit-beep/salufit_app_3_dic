import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  final String? userId;
  final String? userRole;
  const HomeScreen({super.key, this.userId, this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(homeTabProvider);
    final selectedDate = ref.watch(bookingDateProvider);

    return Scaffold(
      appBar: AppBar(title: Text('sALUFIT: $userRole')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Usuario: $userId'),
            Text('Fecha seleccionada: $selectedDate'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (index) => ref.read(homeTabProvider.notifier).setTab(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Citas'),
        ],
      ),
    );
  }
}
