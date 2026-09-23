import 'dart:convert';

import 'package:flutter/services.dart';

class HotelImage {
  const HotelImage({required this.preview, required this.thumb});

  final String preview;
  final String thumb;

  factory HotelImage.fromJson(Map<String, dynamic> json) => HotelImage(
        preview: json['preview'] as String,
        thumb: json['thumb'] as String? ?? json['preview'] as String,
      );
}

class ReferenceHotel {
  ReferenceHotel({
    required this.id,
    required this.rank,
    required this.qualityTier,
    required this.name,
    required this.shortName,
    required this.tone,
    required this.location,
    required this.distanceToVenue,
    this.contactPhone,
    required this.description,
    required this.roomSummary,
    required this.rateStatus,
    required this.highlights,
    required this.rooms,
    required this.images,
    required this.photoCount,
    this.latitude,
    this.longitude,
  });

  final String id;
  final int rank;
  final String qualityTier;
  final String name;
  final String shortName;
  final String tone;
  final String location;
  final String distanceToVenue;
  final String? contactPhone;
  final String description;
  final String roomSummary;
  final String rateStatus;
  final List<String> highlights;
  final List<Map<String, String>> rooms;
  final List<HotelImage> images;
  final int photoCount;
  final double? latitude;
  final double? longitude;

  String get tierLabel => switch (qualityTier) {
        'premier' => 'Premier',
        'value' => 'Value',
        _ => 'Standard',
      };

  /// Straight-line distance to the ICC venue in km, when the sheet lists it.
  double? get distanceKm {
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(distanceToVenue);
    if (m == null) return null;
    return double.tryParse(m.group(1)!);
  }

  /// Cheapest nightly rate parsed from the room tariff (in naira), null if none.
  int? get minRate {
    int? best;
    for (final r in rooms) {
      final matches = RegExp(r'N\s?([\d,]+)').allMatches(r['rate'] ?? '');
      for (final m in matches) {
        final v = int.tryParse(m.group(1)!.replaceAll(',', ''));
        if (v != null && (best == null || v < best)) best = v;
      }
    }
    return best;
  }

  /// First numeric rate across the tariff — used for range filtering.
  bool get hasRates => minRate != null;

  factory ReferenceHotel.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List? ?? [])
        .map((e) => HotelImage.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReferenceHotel(
      id: json['id'] as String,
      rank: json['rank'] as int? ?? 99,
      qualityTier: () {
        final t = json['qualityTier'] as String? ?? 'standard';
        return t == 'pending' ? 'standard' : t;
      }(),
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      tone: json['tone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      distanceToVenue: json['distanceToVenue'] as String? ?? '',
      contactPhone: json['contactPhone'] as String?,
      description: json['description'] as String? ?? '',
      roomSummary: json['roomSummary'] as String? ?? '',
      rateStatus: json['rateStatus'] as String? ?? '',
      highlights: (json['highlights'] as List? ?? [])
          .map((e) => e.toString())
          .where((s) => s.length > 4 && !s.contains(',\n'))
          .toList(),
      rooms: (json['rooms'] as List? ?? [])
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      images: images,
      photoCount: json['photoCount'] as int? ?? images.length,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class ConferenceInfo {
  ConferenceInfo({
    required this.organizationName,
    required this.conferenceTitle,
    required this.theme,
    required this.dates,
    required this.venue,
    required this.chairman,
    required this.logoUrl,
    required this.officialSite,
    required this.stats,
    required this.entertainment,
    required this.spouses,
  });

  final String organizationName;
  final String conferenceTitle;
  final String theme;
  final String dates;
  final String venue;
  final String chairman;
  final String logoUrl;
  final String officialSite;
  final List<Map<String, String>> stats;
  final Map<String, String> entertainment;
  final Map<String, String> spouses;

  factory ConferenceInfo.fromJson(Map<String, dynamic> json) {
    return ConferenceInfo(
      organizationName: json['organizationName'] as String,
      conferenceTitle: json['conferenceTitle'] as String,
      theme: json['theme'] as String,
      dates: json['dates'] as String,
      venue: json['venue'] as String,
      chairman: json['chairman'] as String,
      logoUrl: json['logoUrl'] as String,
      officialSite: json['officialSite'] as String,
      stats: (json['stats'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      entertainment: Map<String, String>.from(json['entertainment'] as Map),
      spouses: Map<String, String>.from(json['spouses'] as Map),
    );
  }
}

class ReferenceData {
  static List<ReferenceHotel>? _hotels;
  static ConferenceInfo? _info;

  /// Last loaded hotels list — lets the map tab read hotels synchronously.
  static List<ReferenceHotel>? get cachedHotels => _hotels;

  static Future<List<ReferenceHotel>> hotels() async {
    _hotels ??= await _loadHotels();
    return _hotels!;
  }

  static Future<ReferenceHotel?> hotelById(String id) async {
    final list = await hotels();
    return list.where((h) => h.id == id).firstOrNull;
  }

  static Future<ConferenceInfo> conferenceInfo() async {
    _info ??= await _loadInfo();
    return _info!;
  }

  static Map<String, dynamic>? _pois;

  static Future<Map<String, dynamic>> maiduguriPois() async {
    _pois ??= jsonDecode(
      await rootBundle.loadString('assets/data/maiduguri_pois.json'),
    ) as Map<String, dynamic>;
    return _pois!;
  }

  static Future<List<ReferenceHotel>> _loadHotels() async {
    final raw = await rootBundle.loadString('assets/data/hotels.json');
    final list = jsonDecode(raw) as List;
    final hotels =
        list.map((e) => ReferenceHotel.fromJson(e as Map<String, dynamic>)).toList();
    hotels.sort((a, b) => a.rank.compareTo(b.rank));
    return hotels;
  }

  static Future<ConferenceInfo> _loadInfo() async {
    final raw = await rootBundle.loadString('assets/data/conference_info.json');
    return ConferenceInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
