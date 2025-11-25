import 'package:flutter/material.dart';
import 'material_screen.dart';
import 'class_list_screen.dart';
import 'profile_screen.dart'; 
import 'placeholder_screens.dart'; 
import 'documents_screen.dart';
import 'professional_panel_widget.dart'; 
import 'professional_resources_screen.dart'; // <--- IMPORT NUEVO

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userRole; 

  const HomeScreen({super.key, required this.userId, this.userRole = "cliente"});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _configurarMenu();
  }

  void _configurarMenu() {
    String rol = widget.userRole.toLowerCase().trim();
    bool esProfesional = rol == "profesional" || rol == "admin";

    if (esProfesional) {
      // --- MENÚ PROFESIONAL (5 Pestañas) ---
      // 1. Panel
      // 2. Inicio
      // 3. Perfil
      // 4. Clases
      // 5. RECURSOS (Docs + Material combinados)
      
      _pages = [
        ProfessionalPanelWidget(userId: widget.userId, userRole: widget.userRole), // 0
        DashboardScreen(userId: widget.userId),         // 1
        ProfileScreen(userId: widget.userId),           // 2
        ClassListScreen(userId: widget.userId),         // 3
        ProfessionalResourcesScreen(userId: widget.userId), // 4. COMBINADA
      ];

      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Panel'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Clases'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_special), label: 'Recursos'), // Icono diferente
      ];

    } else {
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}