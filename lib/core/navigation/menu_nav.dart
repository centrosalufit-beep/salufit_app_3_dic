import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'menu_nav.g.dart';

@riverpod
class MenuIndex extends _$MenuIndex {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

class MenuNavScreen extends ConsumerWidget {
  const MenuNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(menuIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          Center(child: Text('1. Inicio (Reseña Google y Próxima Clase)')),
          Center(child: Text('2. Clases (Tarjetas Discover)')),
          Center(child: Text('3. Material (Contador 0/2)')),
          Center(child: Text('4. Perfil (Tokens y QR)')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(menuIndexProvider.notifier).setIndex(index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Clases'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Material'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
