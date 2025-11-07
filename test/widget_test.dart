import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nav_aif_fyp/main.dart';

void main() {
  testWidgets('NavAI app loads successfully', (WidgetTester tester) async {
  // Build our app and trigger a frame.
  await tester.pumpWidget(const NavAIApp());

  // Verify that the app built and some core widgets are present.
  expect(find.byType(MaterialApp), findsOneWidget);
  expect(find.byType(ElevatedButton), findsWidgets);
  });

  testWidgets('Navigation buttons are present and functional', (WidgetTester tester) async {
  await tester.pumpWidget(const NavAIApp());

  // Verify main buttons exist and can be interacted with
  expect(find.byType(ElevatedButton), findsWidgets);
  // Try tapping the first elevated button to ensure no exceptions
  final firstButton = find.byType(ElevatedButton).first;
  await tester.tap(firstButton);
  await tester.pumpAndSettle();
  });

  testWidgets('Animation containers are present', (WidgetTester tester) async {
  await tester.pumpWidget(const NavAIApp());

  // Verify the animation/custom paint widget is present on the home page
  expect(find.byType(CustomPaint), findsWidgets);
  });
}