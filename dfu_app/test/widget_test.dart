import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dfu_app/main.dart';

void main() {
  testWidgets('clinician can sign in and reach patient list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DfuApp());

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(0),
      'clinician@example.com',
    );
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Patients'), findsOneWidget);
    expect(find.text('Amina Yusuf'), findsOneWidget);
  });

  testWidgets('invalid credentials remain on login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DfuApp());
    await tester.enterText(find.byType(TextField).at(0), 'invalid');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.textContaining('Enter a valid email'), findsOneWidget);
  });

  testWidgets('patient detail opens the new analysis choices', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DfuApp());
    await tester.enterText(
      find.byType(TextField).at(0),
      'clinician@example.com',
    );
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amina Yusuf'));
    await tester.pumpAndSettle();
    expect(find.text('New analysis'), findsOneWidget);

    await tester.tap(find.text('New analysis'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Upload from files'), findsOneWidget);
  });
}
