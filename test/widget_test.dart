import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_mobile/features/auth/auth_screen.dart';

void main() {
  testWidgets('Auth screen builds (smoke)', (tester) async {
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
    
    // Check for tab labels
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
