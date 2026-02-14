import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  // Controlador optimizado para QR y velocidad
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // Detener cámara para liberar recursos y evitar crash
        unawaited(_controller.stop());
        return;
      case AppLifecycleState.resumed:
        // Reiniciar cámara al volver
        unawaited(_controller.start());
        return;
      case AppLifecycleState.inactive:
        // En iOS inactive puede preceder a paused
        unawaited(_controller.stop());
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solución Linter: omit_local_variable_types
    const overlayColor = Color.fromRGBO(0, 0, 0, 0.7);
    const accentColor = Colors.teal;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // CAPA 1: Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (
              BuildContext context,
              MobileScannerException error,
            ) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Error de cámara: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _controller.start,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            },
          ),

          // CAPA 2: Overlay Visual
          Container(
            decoration: const ShapeDecoration(
              shape: ScannerOverlayShape(
                borderColor: accentColor,
                borderRadius: 12,
                // Solución Linter: avoid_redundant_argument_values (borderLength 40 es default)
                // Solución Linter: prefer_int_literals (6 en lugar de 6.0)
                borderWidth: 6,
                cutOutSize: 280,
                overlayColor: overlayColor,
              ),
            ),
          ),

          // CAPA 3: Controles e Información (SafeArea)
          SafeArea(
            child: Column(
              children: <Widget>[
                // Header: Botón Atrás
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text(
                        'Escanear Pase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: <Shadow>[
                            // Solución Linter: avoid_redundant_argument_values (color black es default)
                            Shadow(blurRadius: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer para centrar título
                    ],
                  ),
                ),

                const Spacer(),

                // Texto informativo
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Apunta al código QR del usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Controles Flotantes
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Botón Flash
                      ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (
                          BuildContext context,
                          MobileScannerState state,
                          Widget? child,
                        ) {
                          final isFlashOn = state.torchState == TorchState.on;
                          final isUnavailable =
                              state.torchState == TorchState.unavailable;

                          return _ControlButton(
                            icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: isFlashOn ? Colors.yellow : Colors.white,
                            onPressed:
                                isUnavailable ? null : _controller.toggleTorch,
                          );
                        },
                      ),

                      const SizedBox(width: 40),

                      // Botón Cámara
                      _ControlButton(
                        icon: Icons.cameraswitch,
                        // Solución Linter: avoid_redundant_argument_values (color white es default)
                        onPressed: _controller.switchCamera,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget auxiliar para botones de control
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onPressed,
        padding: const EdgeInsets.all(15),
      ),
    );
  }
}

/// ShapeBorder de alto rendimiento para el recorte del escáner
class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    // Retorna el camino del "agujero"
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final screenPath = Path()..addRect(rect);
    final cutOutPath = getInnerPath(rect);

    // Operación matemática de caminos (Diferencia)
    return Path.combine(PathOperation.difference, screenPath, cutOutPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;

    // 1. Pintar Fondo Oscuro
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), backgroundPaint);

    // 2. Pintar Bordes (Esquinas)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - cutOutSize / 2 + borderOffset,
      cutOutSize - borderOffset * 2,
      cutOutSize - borderOffset * 2,
    );

    final path = Path()
      // Esquina Superior Izquierda
      ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
      ..arcToPoint(
        Offset(cutOutRect.left + borderRadius, cutOutRect.top),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.top)

      // Esquina Superior Derecha
      ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
      ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
      ..arcToPoint(
        Offset(cutOutRect.right, cutOutRect.top + borderRadius),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(cutOutRect.right, cutOutRect.top + borderLength)

      // Esquina Inferior Derecha
      ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
      ..arcToPoint(
        Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom)

      // Esquina Inferior Izquierda
      ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
      ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
      ..arcToPoint(
        Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
