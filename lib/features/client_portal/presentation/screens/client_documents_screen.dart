import 'package:flutter/material.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ClientDocumentsScreen extends StatefulWidget {
  const ClientDocumentsScreen({required this.userId, this.embedMode = false, super.key});
  final String userId;
  final bool embedMode;

  @override
  State<ClientDocumentsScreen> createState() => _ClientDocumentsScreenState();
}

class _ClientDocumentsScreenState extends State<ClientDocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color salufitTeal = Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            TabBar(
              controller: _tabController,
              labelColor: salufitTeal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: salufitTeal,
              tabs: const [Tab(text: 'DOCUMENTOS'), Tab(text: 'MÉTRICAS'), Tab(text: 'DIARIO')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                // CORRECCIÓN: Añadido const a la lista de hijos
                children: const [
                  Center(child: Text('Tus documentos firmados aparecerán aquí')),
                  Center(child: Text('Gráficas de evolución próximamente')),
                  Center(child: Text('Escribe tus sensaciones diarias')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MI EXPEDIENTE', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w900, color: salufitTeal, letterSpacing: 1.2)),
          Text('Historial, Datos y Evolución', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
