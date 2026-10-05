import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bilbax/core/constants/app_strings.dart';
import 'package:bilbax/features/bills/presentation/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shell renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text(AppStrings.appName), findsWidgets);
    expect(find.text('Phase 0 bootstrap ✓'), findsOneWidget);
  });
}
