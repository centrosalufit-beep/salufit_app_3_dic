import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import '../widgets/salufit_scaffold.dart'; // <--- IMPORT NUEVO

// Imports de tus pantallas
import 'material_screen.dart';
import 'class_list_screen.dart';
import 'profile_screen.dart'; 
import 'placeholder_screens.dart'; 
import 'documents_screen.dart';
import 'professional_panel_widget.dart'; 
import 'professional_resources_screen.dart';
import 'login_screen.dart'; // Necesario si usas Navigator para salir

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
  
  bool _esProfesional = false;

  @override
  void initState() {
    super.initState();
    _configurarMenu();
    // NOTA: NotificationService se inicializa aquí o en main, según tu preferencia
  }

  void _configurarMenu() {
    final String rol = widget.userRole.toLowerCase().trim();
    
    print('🔍 SALUFIT DEBUG: HomeScreen cargada.');
    print('   -> ID Usuario: ${widget.userId}');
    print('   -> Rol recibido: "${widget.userRole}" (Procesado: "$rol")');

    _esProfesional = (rol == "profesional" || rol == "admin" || rol == "administrador");

    if (_esProfesional) {
      print('✅ Modo PROFESIONAL/ADMIN activado');
      
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
    // USAMOS EL WIDGET PERSONALIZADO CON FONDO
    return SalufitScaffold( 
      // El cuerpo cambia según la pestaña seleccionada
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