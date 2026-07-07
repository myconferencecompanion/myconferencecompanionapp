import 'package:flutter/material.dart';

/// Official ICC plan raster size (all three sheets share this canvas).
const venuePlanWidth = 3640.0;
const venuePlanHeight = 2573.0;

enum VenuePoiCategory {
  session,
  facility,
  entrance,
  anchor,
  parking,
}

/// A graph node on a floor plan (normalized 0–1 coordinates).
class VenueNode {
  const VenueNode({required this.id, required this.nx, required this.ny});

  final String id;
  final double nx;
  final double ny;

  double get px => nx * venuePlanWidth;
  double get py => ny * venuePlanHeight;
}

/// A delegate-facing place on the map.
class VenuePoi {
  const VenuePoi({
    required this.id,
    required this.floorId,
    required this.nodeId,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.icon,
    this.keywords = const [],
    this.anchorId,
  });

  final String id;
  final String floorId;
  final String nodeId;
  final String name;
  final String subtitle;
  final VenuePoiCategory category;
  final IconData icon;
  final List<String> keywords;
  /// QR anchor id (scan sets "you are here" to this POI's node).
  final String? anchorId;
}

/// One navigable floor / site sheet.
class VenueFloor {
  const VenueFloor({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.image,
    required this.thumb,
    required this.nodes,
    required this.edges,
    required this.pois,
    this.stairsNodeId,
    this.linkedFloorId,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String image;
  final String thumb;
  final List<VenueNode> nodes;
  final List<(String, String)> edges;
  final List<VenuePoi> pois;
  final String? stairsNodeId;
  final String? linkedFloorId;

  VenueNode? node(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  VenuePoi? poi(String id) {
    for (final p in pois) {
      if (p.id == id) return p;
    }
    return null;
  }

  VenuePoi? poiByAnchor(String anchorId) {
    for (final p in pois) {
      if (p.anchorId == anchorId) return p;
    }
    return null;
  }
}

/// Bundled venue navigation data for ICC Maiduguri.
class VenueNavigation {
  const VenueNavigation._();

  static const tourVideo = 'assets/venue/venue_tour.mp4';

  static const floors = <VenueFloor>[
  groundFloor,
  firstFloor,
  siteLayout,
  ];

  static const groundFloor = VenueFloor(
    id: 'ground_floor',
    title: 'Ground floor',
    shortTitle: 'Ground',
    image: 'assets/venue/plans/ground_floor.png',
    thumb: 'assets/venue/plans/thumb/ground_floor.png',
    stairsNodeId: 'stairs',
    linkedFloorId: 'first_floor',
    nodes: [
      VenueNode(id: 'entrance', nx: 0.50, ny: 0.90),
      VenueNode(id: 'foyer_s', nx: 0.50, ny: 0.72),
      VenueNode(id: 'foyer_c', nx: 0.50, ny: 0.56),
      VenueNode(id: 'foyer_n', nx: 0.50, ny: 0.38),
      VenueNode(id: 'stairs', nx: 0.50, ny: 0.48),
      VenueNode(id: 'aud_main', nx: 0.20, ny: 0.50),
      VenueNode(id: 'aud_multi', nx: 0.80, ny: 0.50),
      VenueNode(id: 'banquet', nx: 0.50, ny: 0.14),
      VenueNode(id: 'registration', nx: 0.58, ny: 0.64),
      VenueNode(id: 'food', nx: 0.64, ny: 0.70),
      VenueNode(id: 'toilets', nx: 0.38, ny: 0.62),
      VenueNode(id: 'prayer', nx: 0.34, ny: 0.42),
      VenueNode(id: 'medical', nx: 0.66, ny: 0.42),
      VenueNode(id: 'meeting', nx: 0.28, ny: 0.28),
      VenueNode(id: 'west_j', nx: 0.32, ny: 0.50),
      VenueNode(id: 'east_j', nx: 0.68, ny: 0.50),
    ],
    edges: [
      ('entrance', 'foyer_s'),
      ('foyer_s', 'foyer_c'),
      ('foyer_c', 'foyer_n'),
      ('foyer_c', 'stairs'),
      ('foyer_c', 'registration'),
      ('foyer_c', 'food'),
      ('foyer_c', 'toilets'),
      ('foyer_c', 'west_j'),
      ('foyer_c', 'east_j'),
      ('west_j', 'aud_main'),
      ('west_j', 'prayer'),
      ('west_j', 'meeting'),
      ('east_j', 'aud_multi'),
      ('east_j', 'medical'),
      ('foyer_n', 'banquet'),
      ('stairs', 'foyer_n'),
    ],
    pois: [
      VenuePoi(
        id: 'gf_entrance',
        floorId: 'ground_floor',
        nodeId: 'entrance',
        name: 'Main entrance',
        subtitle: 'Kano/Jos–Maiduguri road · registration desk nearby',
        category: VenuePoiCategory.entrance,
        icon: Icons.door_front_door_rounded,
        keywords: ['entry', 'arrival', 'lobby'],
        anchorId: 'gf_entrance',
      ),
      VenuePoi(
        id: 'gf_foyer',
        floorId: 'ground_floor',
        nodeId: 'foyer_c',
        name: 'Central foyer',
        subtitle: 'Main circulation hub — follow signage to halls',
        category: VenuePoiCategory.facility,
        icon: Icons.hub_rounded,
        keywords: ['lobby', 'foyer', 'center'],
        anchorId: 'gf_foyer',
      ),
      VenuePoi(
        id: 'gf_auditorium',
        floorId: 'ground_floor',
        nodeId: 'aud_main',
        name: 'Main auditorium',
        subtitle: 'Plenary sessions & opening ceremony',
        category: VenuePoiCategory.session,
        icon: Icons.theaters_rounded,
        keywords: ['hall', 'plenary', 'keynote', 'opening'],
      ),
      VenuePoi(
        id: 'gf_banquet',
        floorId: 'ground_floor',
        nodeId: 'banquet',
        name: 'Banquet hall',
        subtitle: 'Gala dinners & large receptions',
        category: VenuePoiCategory.session,
        icon: Icons.restaurant_rounded,
        keywords: ['dinner', 'gala', 'banquet'],
      ),
      VenuePoi(
        id: 'gf_multipurpose',
        floorId: 'ground_floor',
        nodeId: 'aud_multi',
        name: 'Multi-purpose auditorium',
        subtitle: 'Breakout plenaries & parallel sessions',
        category: VenuePoiCategory.session,
        icon: Icons.groups_rounded,
        keywords: ['breakout', 'parallel', 'hall'],
      ),
      VenuePoi(
        id: 'gf_registration',
        floorId: 'ground_floor',
        nodeId: 'registration',
        name: 'Registration',
        subtitle: 'Delegate badges & help desk',
        category: VenuePoiCategory.facility,
        icon: Icons.badge_rounded,
        keywords: ['badge', 'check-in', 'desk'],
        anchorId: 'gf_registration',
      ),
      VenuePoi(
        id: 'gf_food',
        floorId: 'ground_floor',
        nodeId: 'food',
        name: 'Catering point',
        subtitle: 'Complimentary delegate meals',
        category: VenuePoiCategory.facility,
        icon: Icons.restaurant_menu_rounded,
        keywords: ['food', 'lunch', 'catering', 'meal'],
      ),
      VenuePoi(
        id: 'gf_toilets',
        floorId: 'ground_floor',
        nodeId: 'toilets',
        name: 'Toilets',
        subtitle: 'Ground floor restrooms',
        category: VenuePoiCategory.facility,
        icon: Icons.wc_rounded,
        keywords: ['restroom', 'wc', 'bathroom'],
      ),
      VenuePoi(
        id: 'gf_prayer',
        floorId: 'ground_floor',
        nodeId: 'prayer',
        name: 'Prayer room',
        subtitle: 'Quiet space for prayer',
        category: VenuePoiCategory.facility,
        icon: Icons.mosque_rounded,
        keywords: ['prayer', 'mosque', 'quiet'],
      ),
      VenuePoi(
        id: 'gf_medical',
        floorId: 'ground_floor',
        nodeId: 'medical',
        name: 'First aid',
        subtitle: 'Medical support · ask any usher',
        category: VenuePoiCategory.facility,
        icon: Icons.medical_services_rounded,
        keywords: ['medical', 'health', 'doctor', 'nurse'],
      ),
      VenuePoi(
        id: 'gf_meeting',
        floorId: 'ground_floor',
        nodeId: 'meeting',
        name: 'Meeting room',
        subtitle: 'Committee & side meetings',
        category: VenuePoiCategory.session,
        icon: Icons.meeting_room_rounded,
        keywords: ['meeting', 'committee'],
      ),
      VenuePoi(
        id: 'gf_stairs',
        floorId: 'ground_floor',
        nodeId: 'stairs',
        name: 'Stairs to first floor',
        subtitle: 'Central staircase & lifts',
        category: VenuePoiCategory.facility,
        icon: Icons.stairs_rounded,
        keywords: ['stairs', 'lift', 'elevator', 'up'],
        anchorId: 'gf_stairs',
      ),
    ],
  );

  static const firstFloor = VenueFloor(
    id: 'first_floor',
    title: 'First floor',
    shortTitle: '1st',
    image: 'assets/venue/plans/first_floor.png',
    thumb: 'assets/venue/plans/thumb/first_floor.png',
    stairsNodeId: 'stairs',
    linkedFloorId: 'ground_floor',
    nodes: [
      VenueNode(id: 'stairs', nx: 0.50, ny: 0.48),
      VenueNode(id: 'lobby', nx: 0.50, ny: 0.56),
      VenueNode(id: 'aud_upper', nx: 0.22, ny: 0.50),
      VenueNode(id: 'gallery', nx: 0.72, ny: 0.44),
      VenueNode(id: 'seminar', nx: 0.74, ny: 0.20),
      VenueNode(id: 'director', nx: 0.76, ny: 0.74),
      VenueNode(id: 'toilets', nx: 0.38, ny: 0.40),
      VenueNode(id: 'west_j', nx: 0.34, ny: 0.50),
      VenueNode(id: 'east_j', nx: 0.66, ny: 0.50),
    ],
    edges: [
      ('stairs', 'lobby'),
      ('lobby', 'west_j'),
      ('lobby', 'east_j'),
      ('west_j', 'aud_upper'),
      ('west_j', 'toilets'),
      ('east_j', 'gallery'),
      ('east_j', 'seminar'),
      ('east_j', 'director'),
    ],
    pois: [
      VenuePoi(
        id: 'ff_stairs',
        floorId: 'first_floor',
        nodeId: 'stairs',
        name: 'Stairs from ground',
        subtitle: 'Central staircase & lifts',
        category: VenuePoiCategory.facility,
        icon: Icons.stairs_rounded,
        keywords: ['stairs', 'down', 'lift'],
        anchorId: 'ff_stairs',
      ),
      VenuePoi(
        id: 'ff_lobby',
        floorId: 'first_floor',
        nodeId: 'lobby',
        name: 'First floor lobby',
        subtitle: 'Upper circulation area',
        category: VenuePoiCategory.facility,
        icon: Icons.hub_rounded,
        keywords: ['lobby', 'foyer'],
        anchorId: 'ff_lobby',
      ),
      VenuePoi(
        id: 'ff_auditorium',
        floorId: 'first_floor',
        nodeId: 'aud_upper',
        name: 'Upper auditorium',
        subtitle: 'Gallery seating & overflow',
        category: VenuePoiCategory.session,
        icon: Icons.theaters_rounded,
        keywords: ['auditorium', 'gallery', 'plenary'],
      ),
      VenuePoi(
        id: 'ff_gallery',
        floorId: 'first_floor',
        nodeId: 'gallery',
        name: 'Exhibition gallery',
        subtitle: 'Posters & sponsor displays',
        category: VenuePoiCategory.session,
        icon: Icons.museum_rounded,
        keywords: ['exhibition', 'posters', 'sponsors'],
      ),
      VenuePoi(
        id: 'ff_seminar',
        floorId: 'first_floor',
        nodeId: 'seminar',
        name: 'Seminar room',
        subtitle: 'Workshops & technical sessions',
        category: VenuePoiCategory.session,
        icon: Icons.school_rounded,
        keywords: ['seminar', 'workshop', 'session'],
      ),
      VenuePoi(
        id: 'ff_director',
        floorId: 'first_floor',
        nodeId: 'director',
        name: 'Director office',
        subtitle: 'Organising committee & admin',
        category: VenuePoiCategory.facility,
        icon: Icons.business_rounded,
        keywords: ['office', 'admin', 'committee'],
      ),
      VenuePoi(
        id: 'ff_toilets',
        floorId: 'first_floor',
        nodeId: 'toilets',
        name: 'Toilets',
        subtitle: 'First floor restrooms',
        category: VenuePoiCategory.facility,
        icon: Icons.wc_rounded,
        keywords: ['restroom', 'wc'],
      ),
    ],
  );

  static const siteLayout = VenueFloor(
    id: 'icc_layout',
    title: 'Site & parking',
    shortTitle: 'Site',
    image: 'assets/venue/plans/icc_layout.png',
    thumb: 'assets/venue/plans/thumb/icc_layout.png',
    nodes: [
      VenueNode(id: 'road', nx: 0.50, ny: 0.88),
      VenueNode(id: 'parking_s', nx: 0.55, ny: 0.72),
      VenueNode(id: 'parking_n', nx: 0.45, ny: 0.62),
      VenueNode(id: 'centre', nx: 0.50, ny: 0.48),
      VenueNode(id: 'exhibition', nx: 0.50, ny: 0.28),
      VenueNode(id: 'hotel', nx: 0.50, ny: 0.12),
    ],
    edges: [
      ('road', 'parking_s'),
      ('parking_s', 'parking_n'),
      ('parking_n', 'centre'),
      ('centre', 'exhibition'),
      ('exhibition', 'hotel'),
    ],
    pois: [
      VenuePoi(
        id: 'site_entrance',
        floorId: 'icc_layout',
        nodeId: 'road',
        name: 'Main road entrance',
        subtitle: 'Kano/Jos–Maiduguri road approach',
        category: VenuePoiCategory.entrance,
        icon: Icons.directions_car_rounded,
        keywords: ['arrival', 'drive', 'road'],
        anchorId: 'site_entrance',
      ),
      VenuePoi(
        id: 'site_parking',
        floorId: 'icc_layout',
        nodeId: 'parking_s',
        name: 'Delegate parking',
        subtitle: 'Interlocking pavement · follow marshals',
        category: VenuePoiCategory.parking,
        icon: Icons.local_parking_rounded,
        keywords: ['parking', 'car', 'bus'],
        anchorId: 'site_parking',
      ),
      VenuePoi(
        id: 'site_centre',
        floorId: 'icc_layout',
        nodeId: 'centre',
        name: 'Conference centre',
        subtitle: 'Main ICC building',
        category: VenuePoiCategory.entrance,
        icon: Icons.account_balance_rounded,
        keywords: ['icc', 'building', 'venue'],
        anchorId: 'site_centre',
      ),
      VenuePoi(
        id: 'site_exhibition',
        floorId: 'icc_layout',
        nodeId: 'exhibition',
        name: 'Exhibition park',
        subtitle: 'Outdoor displays & networking lawn',
        category: VenuePoiCategory.facility,
        icon: Icons.park_rounded,
        keywords: ['exhibition', 'outdoor', 'lawn'],
      ),
      VenuePoi(
        id: 'site_hotel',
        floorId: 'icc_layout',
        nodeId: 'hotel',
        name: 'On-site hotel',
        subtitle: 'Accommodation block north of ICC',
        category: VenuePoiCategory.facility,
        icon: Icons.hotel_rounded,
        keywords: ['hotel', 'stay'],
      ),
    ],
  );

  static VenueFloor floor(String id) => floors.firstWhere((f) => f.id == id);

  static VenuePoi? poiById(String id) {
    for (final f in floors) {
      final p = f.poi(id);
      if (p != null) return p;
    }
    return null;
  }

  static VenuePoi? poiByAnchor(String anchorId) {
    for (final f in floors) {
      final p = f.poiByAnchor(anchorId);
      if (p != null) return p;
    }
    return null;
  }

  static List<VenuePoi> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final hits = <VenuePoi>[];
    for (final f in floors) {
      for (final p in f.pois) {
        if (p.category == VenuePoiCategory.anchor) continue;
        final blob = '${p.name} ${p.subtitle} ${p.keywords.join(' ')} ${f.title}'.toLowerCase();
        if (blob.contains(q)) hits.add(p);
      }
    }
    return hits;
  }

  /// Parses QR payloads like `nse-venue:gf_entrance` or raw anchor ids.
  static String? parseAnchorFromQr(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    const prefix = 'nse-venue:';
    if (trimmed.toLowerCase().startsWith(prefix)) {
      return trimmed.substring(prefix.length);
    }
    if (trimmed.contains('anchor=')) {
      final uri = Uri.tryParse(trimmed);
      return uri?.queryParameters['anchor'];
    }
    return trimmed;
  }
}
