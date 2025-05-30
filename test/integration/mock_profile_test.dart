import 'package:flutter/material.dart'; import 'package:flutter_test/flutter_test.dart'; import 'package:flutter_application_1/ProfileWidget.dart';

void main() { group('Mock ProfileWidget Tests', () { testWidgets('Displays profile title', (WidgetTester tester) async { await tester.pumpWidget(const MaterialApp(home: ProfileWidget())); await tester.pumpAndSettle(); expect(find.text('Profile'), findsOneWidget); });

testWidgets('Displays theme text', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProfileWidget()));
  await tester.pumpAndSettle();
  expect(find.text('Toggle Theme'), findsOneWidget);
});

testWidgets('Displays language text', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProfileWidget()));
  await tester.pumpAndSettle();
  expect(find.text('English'), findsOneWidget);
});

testWidgets('Has Scaffold', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProfileWidget()));
  await tester.pumpAndSettle();
  expect(find.byType(Scaffold), findsOneWidget);
});

testWidgets('Has no unexpected widgets', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProfileWidget()));
  await tester.pumpAndSettle();
  expect(find.byType(ListView), findsNothing);
});

}); }