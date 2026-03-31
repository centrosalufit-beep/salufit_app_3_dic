import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salufit_app/main.dart';

void main() {
  testWidgets('Salufit integrity smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SalufitApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
