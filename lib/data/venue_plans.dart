import 'package:flutter/material.dart';

/// A bundled ICC architectural plan (rendered from the official PDFs).
class VenuePlan {
  const VenuePlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.thumb,
    required this.icon,
    required this.highlights,
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String thumb;
  final IconData icon;
  final List<String> highlights;
}

/// Offline venue assets bundled from `assets/venue`.
class VenueAssets {
  const VenueAssets._();

  static const tourVideo = 'assets/venue/venue_tour.mp4';

  static const plans = <VenuePlan>[
    VenuePlan(
      id: 'ground_floor',
      title: 'Ground floor',
      subtitle: 'Banquet hall, main auditorium & central foyer',
      image: 'assets/venue/plans/ground_floor.png',
      thumb: 'assets/venue/plans/thumb/ground_floor.png',
      icon: Icons.meeting_room_rounded,
      highlights: ['Main auditorium', 'Banquet hall', 'Central foyer', 'Meeting rooms'],
    ),
    VenuePlan(
      id: 'first_floor',
      title: 'First floor',
      subtitle: 'Auditorium galleries, seminar room & offices',
      image: 'assets/venue/plans/first_floor.png',
      thumb: 'assets/venue/plans/thumb/first_floor.png',
      icon: Icons.stairs_rounded,
      highlights: ['Upper auditorium', 'Galleries', 'Seminar room', 'Director office'],
    ),
    VenuePlan(
      id: 'icc_layout',
      title: 'Site layout',
      subtitle: 'Whole complex, parking, exhibition park & drive-in',
      image: 'assets/venue/plans/icc_layout.png',
      thumb: 'assets/venue/plans/thumb/icc_layout.png',
      icon: Icons.map_rounded,
      highlights: ['Parking', 'Exhibition park', 'Conference centre', 'Access road'],
    ),
  ];
}
