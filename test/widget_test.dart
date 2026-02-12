// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/app.dart';

void main() {
  testWidgets('Shows unlock screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SentimentApp()));
    await tester.pump(const Duration(milliseconds: 600));

    final hasUnlockCopy =
        find.text('Create your lock').evaluate().isNotEmpty ||
        find.text('Unlock your journal').evaluate().isNotEmpty;
    final hasLoading = find
        .byType(CircularProgressIndicator)
        .evaluate()
        .isNotEmpty;

    expect(hasUnlockCopy || hasLoading, isTrue);
  });
}
