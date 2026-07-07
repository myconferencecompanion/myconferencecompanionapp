import 'package:nse_mobile/data/venue_hotspots.dart';

/// Maps session room labels to ICC floor-plan hotspot ids.
const _roomAliases = <String, String>{
  'main hall a': 'hallA',
  'hall a': 'hallA',
  'grand hall': 'grand',
  'main hall': 'grand',
  'hall b': 'hallB',
  'breakout 1': 'workshop',
  'workshop room 1': 'workshop',
  'workshop 1': 'workshop',
  'main lobby': 'lobby',
  'lobby': 'lobby',
  'courtyard': 'courtyard',
  'rooftop terrace': 'rooftop',
  'rooftop': 'rooftop',
};

String? hotspotIdForRoom(String? room) {
  if (room == null || room.trim().isEmpty) return null;
  final key = room.trim().toLowerCase();
  final alias = _roomAliases[key];
  if (alias != null) return alias;
  for (final h in venueHotspots) {
    if (h.name.toLowerCase() == key) return h.id;
  }
  return null;
}

String? hotspotNameForRoom(String? room) {
  final id = hotspotIdForRoom(room);
  if (id == null) return room;
  return venueHotspots.where((h) => h.id == id).firstOrNull?.name ?? room;
}

/// Conference day chips (5 days).
const conferenceDays = [
  (day: 1, label: 'Mon 30'),
  (day: 2, label: 'Tue 1'),
  (day: 3, label: 'Wed 2'),
  (day: 4, label: 'Thu 3'),
  (day: 5, label: 'Fri 4'),
];
