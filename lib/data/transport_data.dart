import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

enum BoardingPolicy { fixedAssignment, openBoarding, hybrid }

BoardingPolicy boardingPolicyFromId(String id) => switch (id) {
      'fixed_assignment' => BoardingPolicy.fixedAssignment,
      'open_boarding' => BoardingPolicy.openBoarding,
      _ => BoardingPolicy.hybrid,
    };

String boardingPolicyId(BoardingPolicy policy) => switch (policy) {
      BoardingPolicy.fixedAssignment => 'fixed_assignment',
      BoardingPolicy.openBoarding => 'open_boarding',
      BoardingPolicy.hybrid => 'hybrid',
    };

String boardingPolicyLabel(BoardingPolicy policy) => switch (policy) {
      BoardingPolicy.fixedAssignment => 'Fixed bus per delegate',
      BoardingPolicy.openBoarding => 'Open boarding by route',
      BoardingPolicy.hybrid => 'Hybrid (recommended)',
    };

class TransportBus {
  const TransportBus({
    required this.id,
    required this.name,
    required this.hotelId,
    required this.routeLabel,
    required this.capacity,
    required this.marshalName,
    required this.marshalPhone,
    required this.pickupPoint,
  });

  final String id;
  final String name;
  final String hotelId;
  final String routeLabel;
  final int capacity;
  final String marshalName;
  final String marshalPhone;
  final String pickupPoint;

  factory TransportBus.fromJson(Map<String, dynamic> json) => TransportBus(
        id: json['id'] as String,
        name: json['name'] as String,
        hotelId: json['hotelId'] as String,
        routeLabel: json['routeLabel'] as String,
        capacity: json['capacity'] as int? ?? 30,
        marshalName: json['marshalName'] as String? ?? '',
        marshalPhone: json['marshalPhone'] as String? ?? '',
        pickupPoint: json['pickupPoint'] as String? ?? 'ICC main entrance',
      );
}

class TransportRun {
  const TransportRun({
    required this.id,
    required this.busId,
    required this.label,
    required this.direction,
    required this.scheduledAt,
    required this.status,
  });

  final String id;
  final String busId;
  final String label;
  final String direction;
  final String scheduledAt;
  final String status;

  bool get isLocked => status == 'departed' || status == 'locked';

  factory TransportRun.fromJson(Map<String, dynamic> json) => TransportRun(
        id: json['id'] as String,
        busId: json['bus_id'] as String? ?? json['busId'] as String,
        label: json['label'] as String? ?? '',
        direction: json['direction'] as String? ?? 'to_hotel',
        scheduledAt: json['scheduled_at'] as String? ?? json['scheduledAt'] as String? ?? '',
        status: json['status'] as String? ?? 'scheduled',
      );
}

class TransportCatalog {
  TransportCatalog({
    required this.defaultPolicy,
    required this.buses,
    required this.scheduleTemplate,
  });

  final BoardingPolicy defaultPolicy;
  final List<TransportBus> buses;
  final List<Map<String, dynamic>> scheduleTemplate;

  static TransportCatalog? _cache;

  static Future<TransportCatalog> load() async {
    _cache ??= await _read();
    return _cache!;
  }

  static Future<TransportCatalog> _read() async {
    final raw = await rootBundle.loadString('assets/data/transport.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return TransportCatalog(
      defaultPolicy: boardingPolicyFromId(json['defaultPolicy'] as String? ?? 'hybrid'),
      buses: (json['buses'] as List)
          .map((e) => TransportBus.fromJson(e as Map<String, dynamic>))
          .toList(),
      scheduleTemplate: (json['scheduleTemplate'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;

String formatDistanceKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}
