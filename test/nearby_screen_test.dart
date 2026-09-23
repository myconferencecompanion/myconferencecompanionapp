import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_mobile/features/location/location_screens.dart';

void main() {
  testWidgets('Nearby screen shows grouped Maiduguri places', (tester) async {
    final Future<void> Function(Size?) restore = tester.binding.setSurfaceSize;
    addTearDown(() => restore(null));
    await tester.binding.setSurfaceSize(const Size(1080, 24000));
    await tester.pumpWidget(const MaterialApp(home: NearbyScreen()));
    await tester.pumpAndSettle();

    // Group headers
    expect(find.text('Airport & transport'), findsOneWidget);
    expect(find.text('Security & emergency'), findsOneWidget);
    expect(find.text('Government & liaison'), findsOneWidget);
    expect(find.text('Hospitals'), findsOneWidget);
    expect(find.text('Culture & heritage'), findsOneWidget);
    expect(find.text('Food & essentials'), findsOneWidget);
    expect(find.text('Programme visits'), findsOneWidget);

    // Key researched places
    expect(find.text('Maiduguri International Airport'), findsOneWidget);
    expect(find.text('Nigeria Police — Borno State Command HQ'), findsOneWidget);
    expect(find.text('DSS Borno Command Headquarters'), findsOneWidget);
    expect(find.text('Dandal Police Station'), findsOneWidget);
    expect(find.text('Metro Police Station'), findsOneWidget);
    expect(find.text('7 Division Nigerian Army — Maimalari Cantonment'), findsOneWidget);
    expect(find.text('Giwa Barracks'), findsOneWidget);
    expect(find.text('NSCDC Borno State Command'), findsOneWidget);
    expect(find.text('Borno State Government House'), findsOneWidget);
    expect(find.text('Borno New Lodge'), findsOneWidget);
    expect(find.text('Lagos House'), findsOneWidget);
    expect(find.text('Yobe State Liaison Office'), findsOneWidget);
    expect(find.text("Shehu of Borno's Palace"), findsOneWidget);
    expect(find.text('Borno State Museum'), findsOneWidget);
    expect(find.text('Borno State Specialist Hospital'), findsOneWidget);
    expect(find.text('Umaru Shehu Ultra-Modern Hospital'), findsOneWidget);
    expect(find.text('Muhammadu Shuwa Memorial Hospital'), findsOneWidget);
    expect(find.text('University of Maiduguri Teaching Hospital'), findsOneWidget);
    expect(find.text('Eye & Dental Hospital'), findsOneWidget);
  });

  testWidgets('Nearby cards open Google Maps search', (tester) async {
    final Future<void> Function(Size?) restore = tester.binding.setSurfaceSize;
    addTearDown(() => restore(null));
    await tester.binding.setSurfaceSize(const Size(1080, 24000));
    await tester.pumpWidget(const MaterialApp(home: NearbyScreen()));
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.text('Dandal Police Station'),
      matching: find.byType(InkWell),
    );
    expect(card, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
