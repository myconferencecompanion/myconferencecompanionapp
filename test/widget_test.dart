import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_mobile/features/auth/auth_screen.dart';

void main() {
  testWidgets('Auth screen builds (smoke)', (tester) async {
    // dotenv must be initialized before Env.isDemoMode reads it.
    await tester.runAsync(() => dotenv.load(fileName: '.env'));

    // Pump the widget
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    // Wait for all animations and async operations
    await tester.pumpAndSettle();

    // Basic checks that the screen builds
    expect(find.byType(AuthScreen), findsOneWidget);

    // Check for tab labels ("Sign in" appears as tab + submit button).
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Register'), findsWidgets);
  });
}
