import 'dart:math' as math;

import 'package:nse_mobile/data/venue_navigation.dart';

/// Result of a multi-floor route request.
class VenueRouteResult {
  const VenueRouteResult({
    required this.segments,
    this.crossFloorNote,
  });

  /// Each segment is on one floor: ordered node ids.
  final List<VenueRouteSegment> segments;
  final String? crossFloorNote;

  bool get isEmpty => segments.isEmpty || segments.every((s) => s.nodeIds.length < 2);
}

class VenueRouteSegment {
  const VenueRouteSegment({required this.floorId, required this.nodeIds});

  final String floorId;
  final List<String> nodeIds;
}

/// A* pathfinding over the ICC corridor graph (pure Dart, offline).
class VenuePathfinder {
  const VenuePathfinder._();

  static VenueRouteResult route({
    required String startFloorId,
    required String startNodeId,
    required String endFloorId,
    required String endNodeId,
  }) {
    if (startFloorId == endFloorId) {
      final path = _astar(startFloorId, startNodeId, endNodeId);
      if (path == null || path.length < 2) return const VenueRouteResult(segments: []);
      return VenueRouteResult(
        segments: [VenueRouteSegment(floorId: startFloorId, nodeIds: path)],
      );
    }

    final startFloor = VenueNavigation.floor(startFloorId);
    final endFloor = VenueNavigation.floor(endFloorId);
    final startStairs = startFloor.stairsNodeId;
    final endStairs = endFloor.stairsNodeId;

    if (startStairs == null || endStairs == null) {
      return VenueRouteResult(
        segments: [],
        crossFloorNote: 'Switch to ${endFloor.shortTitle} floor and navigate from the stairs.',
      );
    }

    final toStairs = _astar(startFloorId, startNodeId, startStairs);
    final fromStairs = _astar(endFloorId, endStairs, endNodeId);

    if (toStairs == null || fromStairs == null) {
      return const VenueRouteResult(segments: []);
    }

    return VenueRouteResult(
      segments: [
        VenueRouteSegment(floorId: startFloorId, nodeIds: toStairs),
        VenueRouteSegment(floorId: endFloorId, nodeIds: fromStairs),
      ],
      crossFloorNote:
          'Take the central stairs / lift to ${endFloor.title}, then continue.',
    );
  }

  static List<String>? _astar(String floorId, String startId, String goalId) {
    if (startId == goalId) return [startId];

    final floor = VenueNavigation.floor(floorId);
    final nodes = {for (final n in floor.nodes) n.id: n};
    if (!nodes.containsKey(startId) || !nodes.containsKey(goalId)) return null;

    final neighbors = <String, List<String>>{};
    for (final e in floor.edges) {
      neighbors.putIfAbsent(e.$1, () => []).add(e.$2);
      neighbors.putIfAbsent(e.$2, () => []).add(e.$1);
    }

    double h(String id) {
      final a = nodes[id]!;
      final b = nodes[goalId]!;
      final dx = a.nx - b.nx;
      final dy = a.ny - b.ny;
      return math.sqrt(dx * dx + dy * dy);
    }

    final open = <String>[startId];
    final cameFrom = <String, String>{};
    final gScore = <String, double>{startId: 0};
    final fScore = <String, double>{startId: h(startId)};

    while (open.isNotEmpty) {
      open.sort((a, b) => (fScore[a] ?? double.infinity).compareTo(fScore[b] ?? double.infinity));
      final current = open.removeAt(0);
      if (current == goalId) {
        return _reconstruct(cameFrom, current);
      }

      for (final next in neighbors[current] ?? const []) {
        final tentative = (gScore[current] ?? double.infinity) + _dist(nodes[current]!, nodes[next]!);
        if (tentative >= (gScore[next] ?? double.infinity)) continue;
        cameFrom[next] = current;
        gScore[next] = tentative;
        fScore[next] = tentative + h(next);
        if (!open.contains(next)) open.add(next);
      }
    }
    return null;
  }

  static double _dist(VenueNode a, VenueNode b) {
    final dx = a.nx - b.nx;
    final dy = a.ny - b.ny;
    return math.sqrt(dx * dx + dy * dy);
  }

  static List<String> _reconstruct(Map<String, String> cameFrom, String current) {
    final path = <String>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }

  /// Human-readable steps for the active floor segment.
  static List<String> stepsForSegment(VenueRouteSegment segment) {
    final floor = VenueNavigation.floor(segment.floorId);
    final steps = <String>[];
    for (var i = 0; i < segment.nodeIds.length; i++) {
      final nodeId = segment.nodeIds[i];
      final poi = floor.pois.where((p) => p.nodeId == nodeId).firstOrNull;
      final label = poi?.name ?? _labelForNode(nodeId);
      if (i == 0) {
        steps.add('Start at $label');
      } else if (i == segment.nodeIds.length - 1) {
        steps.add('Arrive at $label');
      } else {
        steps.add('Continue through $label');
      }
    }
    return steps;
  }

  static String _labelForNode(String id) => id.replaceAll('_', ' ');
}
