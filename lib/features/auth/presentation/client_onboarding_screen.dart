import 'package:flutter/material.dart';

class ClientOnboardingScreen extends StatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  State<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends State<ClientOnboardingScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();
  bool _isLoading = false; // No puede ser final porque cambia en setState

  void _handleValidation() {
    if (_emailController.text.isEmpty || _historyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena todos los campos')),
      );
      return;
    }
    setState(() => _isLoading = true);
    // Simulación de lógica
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleValidation,
          child: const Text('Validar'),
        ),
      ),
    );
  }
}
