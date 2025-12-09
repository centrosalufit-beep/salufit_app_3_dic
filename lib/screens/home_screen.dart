import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import '../widgets/salufit_scaffold.dart';

// Imports de tus pantallas
import 'material_screen.dart';
import 'class_list_screen.dart';
import 'profile_screen.dart'; 
import 'placeholder_screens.dart'; // Aquí está tu DashboardScreen
import 'documents_screen.dart';
import 'professional_panel_widget.dart'; 
import 'professional_resources_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userRole; 

  const HomeScreen({
    super.key, 
    required this.userId, 
    this.userRole = 'cliente'
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;
  
  bool _esProfesional = false;

  @override
  void initState() {
    super.initState();
    _configurarMenu();
  }

  void _configurarMenu() {
    final String rol = widget.userRole.toLowerCase().trim();
    
    if (kDebugMode) {
      print('🔍 SALUFIT DEBUG: HomeScreen cargada.');
      print('   -> ID Usuario: ${widget.userId}');
      print('   -> Rol recibido: "${widget.userRole}"');
    }

    // Detectamos si es Staff (Admin o Profesional)
    _esProfesional = (rol == 'profesional' || rol == 'admin' || rol == 'administrador');

    if (_esProfesional) {
      if (kDebugMode) print('✅ Modo PROFESIONAL/ADMIN activado');
      
      _pages = [
        ProfessionalPanelWidget(userId: widget.userId, userRole: widget.userRole), // 0
        DashboardScreen(userId: widget.userId),         // 1
        ProfileScreen(userId: widget.userId),           // 2
        ClassListScreen(userId: widget.userId),         // 3
        ProfessionalResourcesScreen(userId: widget.userId), // 4
      ];

      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Panel'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Clases'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_special), label: 'Recursos'),
      ];

    } else {
      if (kDebugMode) print('👤 Modo CLIENTE activado');
      
      _pages = [
        DashboardScreen(userId: widget.userId), // 0
        ProfileScreen(userId: widget.userId),   // 1
        ClassListScreen(userId: widget.userId), // 2
        MaterialScreen(userId: widget.userId),  // 3
        DocumentsScreen(userId: widget.userId), // 4
      ];

      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Clases'),
        BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Material'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: 'Docs'),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold( 
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal, 
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
        elevation: 10,
      ),
    );
  }
}