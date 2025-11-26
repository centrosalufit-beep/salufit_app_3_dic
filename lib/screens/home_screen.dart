import 'package:flutter/material.dart';
import 'material_screen.dart';
import 'class_list_screen.dart';
import 'profile_screen.dart'; 
import 'placeholder_screens.dart'; // Contiene DashboardScreen por defecto
import 'documents_screen.dart';
import 'professional_panel_widget.dart'; 
import 'professional_resources_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userRole; 

  const HomeScreen({
    super.key, 
    required this.userId, 
    this.userRole = "cliente"
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;
  
  // Variable para saber si detectamos el rol correctamente
  bool _esProfesional = false;

  @override
  void initState() {
    super.initState();
    _configurarMenu();
  }

  void _configurarMenu() {
    // 1. Normalización del rol para evitar errores de mayúsculas/espacios
    final String rol = widget.userRole.toLowerCase().trim();
    
    // Debug: Veremos en consola qué está llegando
    print('🔍 SALUFIT DEBUG: HomeScreen cargada.');
    print('   -> ID Usuario: ${widget.userId}');
    print('   -> Rol recibido: "${widget.userRole}" (Procesado: "$rol")');

    // 2. Lógica de detección ampliada
    _esProfesional = (rol == "profesional" || rol == "admin" || rol == "administrador");

    if (_esProfesional) {
      print('✅ Modo PROFESIONAL/ADMIN activado');
      
      // --- MENÚ PROFESIONAL (5 Pestañas) ---
      // 1. Panel de Gestión
      // 2. Inicio (Dashboard)
      // 3. Perfil
      // 4. Clases (Vista gestión)
      // 5. Recursos (Gestión de material)
      
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
      print('👤 Modo CLIENTE activado');

      // --- MENÚ CLIENTE (5 Pestañas Estándar) ---
      // Inicio - Perfil - Clases - Material - Docs
      
      _pages = [
        DashboardScreen(userId: widget.userId),        
        ProfileScreen(userId: widget.userId),           
        ClassListScreen(userId: widget.userId),         
        MaterialScreen(userId: widget.userId),          
        DocumentsScreen(userId: widget.userId),         
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
    return Scaffold(
      // El cuerpo cambia según la pestaña seleccionada
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        // COLOR CORPORATIVO (Teal) en lugar de Azul
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