import 'package:flutter/material.dart';
import 'package:flutter_application_1/ProfileWidget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileWidget Tests', () {
    testWidgets('ProfileWidget displays theme switch', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ProfileWidget(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Toggle Theme'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('ProfileWidget theme switch toggles correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ProfileWidget(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('ProfileWidget displays language dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ProfileWidget(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
      expect(find.byKey(const Key('language_dropdown')), findsOneWidget);
    });

    testWidgets('ProfileWidget language dropdown has three options', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ProfileWidget(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language_dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsWidgets);
      expect(find.text('Русский'), findsWidgets);
      expect(find.text('Қазақша'), findsWidgets);
    });

    testWidgets('ProfileWidget language dropdown changes value', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ProfileWidget(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Selected Language: en'), findsOneWidget);
      await tester.tap(find.byKey(const Key('language_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(find.text('Selected Language: ru'), findsOneWidget);
    });
  });
}