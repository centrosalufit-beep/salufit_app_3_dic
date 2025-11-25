import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasScanned = false; // Para evitar escanear 20 veces seguidas

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Pase"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasScanned) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _hasScanned = true;
              final String codigoLeido = barcode.rawValue!;
              
              // Devolvemos el código leído a la pantalla anterior
              Navigator.pop(context, codigoLeido);
              break;
            }
          }
        },
      ),
    );
  }
}