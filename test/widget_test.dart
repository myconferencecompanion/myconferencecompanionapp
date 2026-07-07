import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_mobile/features/auth/auth_screen.dart';

void main() {
  testWidgets('Auth screen builds (smoke)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Register'), findsWidgets);
  });
}
