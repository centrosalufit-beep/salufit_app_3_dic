import 'package:flutter/material.dart';
import '../widgets/salufit_scaffold.dart';
import 'material_screen.dart'; // Pestaña Vídeos
import 'documents_screen.dart'; // Pestaña Docs

class ProfessionalResourcesScreen extends StatelessWidget {
  final String userId;

  const ProfessionalResourcesScreen({super.key, required this.userId});

  // Color corporativo
  final Color salufitTeal = const Color(0xFF009688);

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold(
      body: DefaultTabController(
        length: 2, 
        child: Column(
          children: [
            // --- 1. CABECERA PREMIUM UNIFICADA ---
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Image.asset(
                       'assets/logo_salufit.png', 
                       width: 60, 
                       fit: BoxFit.contain,
                       errorBuilder: (c,e,s) => Icon(Icons.folder_special, size: 60, color: salufitTeal),
                     ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MIS RECURSOS', 
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.w900, 
                              color: salufitTeal,
                              fontFamily: 'serif',
                              letterSpacing: 2.0,
                              height: 1.0,
                              shadows: [Shadow(offset: const Offset(1, 1), color: Colors.black.withValues(alpha: 0.1), blurRadius: 0)]
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text('Material y Documentación', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --- 2. TABS ---
            const TabBar(
              labelColor: Color(0xFF009688),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF009688),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(icon: Icon(Icons.folder_open), text: 'Documentos'),
                Tab(icon: Icon(Icons.play_circle_outline), text: 'Vídeos'),
              ],
            ),

            // --- 3. CONTENIDO (Incrustado sin sus propias cabeceras) ---
            Expanded(
              child: TabBarView(
                children: [
                  // Pasamos embedMode: true para que NO muestre su propia cabecera
                  DocumentsScreen(userId: userId, embedMode: true),
                  
                  // Pasamos embedMode: true para que NO muestre su propia cabecera
                  MaterialScreen(userId: userId, embedMode: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}