import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_mobile/data/reference_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled masterlist loads 47 hotels with required fields', () async {
    final hotels = await ReferenceData.hotels();

    expect(hotels.length, 47);

    final ids = hotels.map((h) => h.id).toSet();
    expect(ids.length, hotels.length, reason: 'hotel ids must be unique');

    final ranks = hotels.map((h) => h.rank).toList()..sort();
    expect(ranks.first, 1);
    expect(ranks.last, 47);

    for (final h in hotels) {
      expect(h.name, isNotEmpty, reason: '${h.id} has a name');
      expect(h.location, isNotEmpty, reason: '${h.id} has a location');
    }

    // Masterlist source of truth: Solace is S/N 1 with sheet data attached.
    final solace = hotels.firstWhere((h) => h.id == 'solce');
    expect(solace.rank, 1);
    expect(solace.distanceToVenue, '5.5 KM');
    expect(solace.contactPhone, isNotNull);
    expect(solace.images, isNotEmpty, reason: 'inspection photos must survive data updates');
  });

  test('quality tiers parse into the three display tiers', () async {
    final hotels = await ReferenceData.hotels();
    for (final h in hotels) {
      expect(['premier', 'standard', 'value'], contains(h.qualityTier),
          reason: '${h.id} tier "${h.qualityTier}" must map to a display tier');
    }
  });

  test('asset bytes are valid JSON', () async {
    final raw = await rootBundle.loadString('assets/data/hotels.json');
    expect(() => jsonDecode(raw), returnsNormally);
  });
}
