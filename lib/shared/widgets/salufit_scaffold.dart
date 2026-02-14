import 'package:flutter/material.dart';

class SalufitScaffold extends StatelessWidget {
  const SalufitScaffold({
    required this.body,
    super.key,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.appBar,
    this.backgroundColor,
    this.showWatermark = true,
  });

  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool showWatermark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (showWatermark) ...[
            Image.asset(
              'assets/watermark_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
            Container(color: Colors.white.withValues(alpha: 0.85)),
          ],
          body,
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
