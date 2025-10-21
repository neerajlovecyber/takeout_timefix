// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:takeout_timefix/main.dart';
import 'package:takeout_timefix/providers/stepper_provider.dart';

void main() {
  test('TakeoutTimeFix app can be instantiated', () {
    // Test that the app widget can be created
    const app = TakeoutTimeFixApp();
    expect(app, isNotNull);
  });

  test('StepperProvider can be created', () {
    // Test that the provider can be created
    final provider = StepperProvider();
    expect(provider, isNotNull);
    expect(provider.currentStep, equals(0));
  });
}
