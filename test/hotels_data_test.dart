import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_mobile/data/reference_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled masterlist loads 46 hotels with required fields', () async {
    final hotels = await ReferenceData.hotels();

    expect(hotels.length, 46);

    final ids = hotels.map((h) => h.id).toSet();
    expect(ids.length, hotels.length, reason: 'hotel ids must be unique');

    final ranks = hotels.map((h) => h.rank).toList()..sort();
    expect(ranks.first, 1);
    expect(ranks.last, 46);

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

  test('masterlist-derived getters work (rates, distance, coords)', () async {
    final hotels = await ReferenceData.hotels();

    // Rate parsing: Solace's cheapest tariff line is N59,000.
    final solace = hotels.firstWhere((h) => h.id == 'solce');
    expect(solace.minRate, 59000);

    // Distance parsing from "5.5 KM".
    expect(solace.distanceKm, 5.5);

    // Geocoding: the 9 OSM-verified hotels carry coordinates.
    final geocoded = hotels.where((h) => h.latitude != null && h.longitude != null).toList();
    expect(geocoded.length, 9);
    expect(geocoded.every((h) => h.latitude! > 11.7 && h.latitude! < 12.0), isTrue);
    expect(geocoded.every((h) => h.longitude! > 13.0 && h.longitude! < 13.3), isTrue);
  });

  test('asset bytes are valid JSON', () async {
    final raw = await rootBundle.loadString('assets/data/hotels.json');
    expect(() => jsonDecode(raw), returnsNormally);
  });
}
