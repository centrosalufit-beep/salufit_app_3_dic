import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobileScaffold,
    required this.desktopScaffold,
    super.key,
  });
  final Widget mobileScaffold;
  final Widget desktopScaffold;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 800) {
          return mobileScaffold;
        } else {
          return desktopScaffold;
        }
      },
    );
  }
}
