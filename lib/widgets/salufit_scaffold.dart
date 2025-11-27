import 'package:flutter/material.dart';

class SalufitScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const SalufitScaffold({
    super.key, 
    required this.body, 
    this.appBar, 
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantenemos el color de fondo base (gris muy claro)
      backgroundColor: backgroundColor ?? const Color(0xFFF5F7FA), 
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      
      // Usamos un Stack para poner la imagen DETRÁS del body
      body: Stack(
        children: [
          // CAPA 1: IMAGEN DE MARCA DE AGUA
          Positioned.fill(
            child: Opacity(
              opacity: 0.25, // <--- 5% DE OPACIDAD (Muy sutil)
              child: Image.asset(
                'assets/watermark_bg.jpg', 
                fit: BoxFit.cover, // Cubre toda la pantalla
              ),
            ),
          ),

          // CAPA 2: EL CONTENIDO REAL DE LA PANTALLA
          body,
        ],
      ),
    );
  }
}