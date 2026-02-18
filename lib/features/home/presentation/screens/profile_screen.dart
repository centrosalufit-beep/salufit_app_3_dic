import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.userId, super.key});
  final String userId;
  static const Color salufitTeal = Color(0xFF009688);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // bypass temporal para Axel mientras localizamos el nuevo provider
    const String name = "AXEL";
    const int tokens = 8;
    const int bookings = 2;

    return SalufitScaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(name)),
            SliverToBoxAdapter(child: _buildQrCard()),
            
            _buildSectionTitle('MIS CRÉDITOS Y RESERVAS'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildSquareCard(
                      icon: Icons.generating_tokens, 
                      color: salufitTeal, 
                      value: "$tokens", 
                      label: "TOKENS\nRESTANTES"
                    )),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSquareCard(
                      icon: Icons.calendar_month, 
                      color: Colors.orange, 
                      value: "$bookings", 
                      label: "RESERVAS\nACTIVAS",
                      onTap: () => debugPrint("Gestionar reservas")
                    )),
                  ],
                ),
              ),
            ),

            _buildSectionTitle('DESCUBRE SALUFIT'),
            SliverToBoxAdapter(child: _buildDiscoverGiftCard(context, name)),

            _buildSectionTitle('GESTIÓN DE CUENTA'),
            SliverToBoxAdapter(child: _buildLogoutButton(ref)),
            SliverToBoxAdapter(child: _buildDeleteAccountButton(context)),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(25, 30, 20, 12),
      child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2)),
    ),
  );

  Widget _buildHeader(String name) => Padding(
    padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontFamily: 'serif', fontSize: 34, fontWeight: FontWeight.w900, color: salufitTeal)),
        const Text('Panel de Usuario Salufit', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _buildQrCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, color: salufitTeal.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 8),
            const Text('LLAVE DE ACCESO AL CENTRO', style: TextStyle(color: salufitTeal, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 20),
        const Icon(Icons.qr_code_scanner, size: 130, color: Color(0xFF263238)),
        const SizedBox(height: 15),
        const Text('Muestra este código al staff para entrar', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );

  Widget _buildSquareCard({required IconData icon, required Color color, required String value, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverGiftCard(BuildContext context, String name) => InkWell(
    onTap: () => _showGiftDialog(context, name),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFFAD1457)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFAD1457).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: const Row(
        children: [
          Icon(Icons.card_giftcard, color: Colors.white, size: 40),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡REGALO DISCOVER!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                Text('Haz clic para ver tus ventajas', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
        ],
      ),
    ),
  );

  Widget _buildLogoutButton(WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 5, 20, 12),
    child: TextButton.icon(
      onPressed: () => ref.read(authServiceProvider).signOut(),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFEEEEEE))),
      ),
      icon: const Icon(Icons.power_settings_new, size: 20),
      label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
    ),
  );

  Widget _buildDeleteAccountButton(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: ElevatedButton(
      onPressed: () => _showDeleteDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('ELIMINAR MI CUENTA DEFINITIVAMENTE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          SizedBox(width: 15),
          Icon(Icons.power_settings_new, size: 20),
        ],
      ),
    ),
  );

  void _showGiftDialog(BuildContext context, String name) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFAD1457), size: 50),
            const SizedBox(height: 20),
            Text('¡BIENVENIDO, $name!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text('Por ser miembro Salufit tienes:', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _giftItem('25€ DTO. en INDIBA o NESA'),
            _giftItem('1 TOKEN EXTRA al mes'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: salufitTeal, minimumSize: const Size(double.infinity, 50)),
              child: const Text('IR A RESERVAR CLASES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _giftItem(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [const Icon(Icons.check_circle, color: salufitTeal, size: 18), const SizedBox(width: 10), Text(text, style: const TextStyle(fontWeight: FontWeight.w700))]),
  );

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Esta acción borrará tus tokens y tu material asignado de forma permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('SÍ, ELIMINAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
