import 'package:nse_mobile/config/event_config.dart';

class VenueHotspot {
  const VenueHotspot({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
  });

  final String id;
  final String name;
  final double x;
  final double y;
}

const venueHotspots = [
  VenueHotspot(id: 'lobby', name: 'Main Lobby', x: 0.50, y: 0.12),
  VenueHotspot(id: 'grand', name: 'Grand Hall', x: 0.50, y: 0.38),
  VenueHotspot(id: 'hallA', name: 'Hall A', x: 0.20, y: 0.55),
  VenueHotspot(id: 'hallB', name: 'Hall B', x: 0.80, y: 0.55),
  VenueHotspot(id: 'workshop', name: 'Workshop Room 1', x: 0.22, y: 0.78),
  VenueHotspot(id: 'courtyard', name: 'Courtyard', x: 0.50, y: 0.65),
  VenueHotspot(id: 'rooftop', name: 'Rooftop Terrace', x: 0.78, y: 0.88),
];

const venueLatLng = (
  lat: EventConfig.venueLatitude,
  lng: EventConfig.venueLongitude,
);
