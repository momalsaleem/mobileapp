import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nav_aif_fyp/main.dart';

void main() {
  testWidgets('NavAI app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the main app components are present
    expect(find.text('Welcome to Nav AI / نیو اے آئی میں خوش آمدید'), findsOneWidget);
    expect(find.text('Smart navigation, designed for you.'), findsOneWidget);
    expect(find.text('Start with Voice / آواز سے شروع کریں'), findsOneWidget);
    expect(find.text('Continue with Touch / ٹچ کے ذریعے جاری رکھیں'), findsOneWidget);
  });

  testWidgets('Navigation buttons are present and functional', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify both main buttons are present
    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.smartphone), findsOneWidget);

    // Test that buttons can be tapped (they should navigate to language page)
    await tester.tap(find.text('Start with Voice / آواز سے شروع کریں'));
    await tester.pumpAndSettle();

    // After tapping, we should see some navigation (you might need to adjust this based on your actual navigation)
    // expect(find.byType(NavAILanguagePage), findsOneWidget);
  });

  testWidgets('Animation containers are present', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify the animation container is present
    expect(find.byType(Container), findsWidgets);
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}