// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:takeout_timefix/main.dart';

void main() {
  testWidgets('TakeoutTimeFix app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TakeoutTimeFixApp());

    // Verify that the app title is displayed.
    expect(find.text('Takeout TimeFix'), findsOneWidget);

    // Verify that the folder selection button is present.
    expect(find.text('Select Takeout Folder'), findsOneWidget);

    // Verify that the main description text is present.
    expect(find.textContaining('Google Photos Takeout Organizer'), findsOneWidget);
  });
}
