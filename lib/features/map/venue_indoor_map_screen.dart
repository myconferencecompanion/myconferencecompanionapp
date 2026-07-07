import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_rastercoords/flutter_map_rastercoords.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/data/venue_navigation.dart';
import 'package:nse_mobile/features/map/venue_pathfinder.dart';
import 'package:nse_mobile/theme/app_theme.dart';

/// Google-Maps-style indoor navigation for ICC Maiduguri.
class VenueIndoorMapScreen extends StatefulWidget {
  const VenueIndoorMapScreen({super.key, this.initialPoiId, this.initialFloorId});

  final String? initialPoiId;
  final String? initialFloorId;

  @override
  State<VenueIndoorMapScreen> createState() => _VenueIndoorMapScreenState();
}

class _VenueIndoorMapScreenState extends State<VenueIndoorMapScreen> {
  final _mapController = MapController();
  late final RasterCoords _rc = RasterCoords(width: venuePlanWidth, height: venuePlanHeight);

  late String _floorId;
  String? _startNodeId;
  String? _startFloorId;
  String? _destPoiId;
  VenueRouteResult? _route;
  String _query = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _floorId = widget.initialFloorId ?? 'ground_floor';
    if (widget.initialPoiId != null) {
      final poi = VenueNavigation.poiById(widget.initialPoiId!);
      if (poi != null) {
        _floorId = poi.floorId;
        _destPoiId = poi.id;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitFloor());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  VenueFloor get _floor => VenueNavigation.floor(_floorId);

  LatLng _latLng(VenueNode n) => _rc.pixelToLatLng(x: n.px, y: n.py);

  void _fitFloor() {
    final bounds = _rc.getMaxBounds();
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(28)),
    );
  }

  void _selectFloor(String id) {
    if (_floorId == id) return;
    setState(() => _floorId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitFloor());
  }

  void _setYouAreHere(VenuePoi anchorPoi) {
    HapticFeedback.mediumImpact();
    setState(() {
      _startNodeId = anchorPoi.nodeId;
      _startFloorId = anchorPoi.floorId;
      if (anchorPoi.floorId != _floorId) _floorId = anchorPoi.floorId;
      _route = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitFloor();
      _focusNode(anchorPoi.nodeId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You are here: ${anchorPoi.name}')),
    );
  }

  void _focusNode(String nodeId) {
    final node = _floor.node(nodeId);
    if (node == null) return;
    _mapController.move(_latLng(node), _mapController.camera.zoom);
  }

  void _selectDestination(VenuePoi poi) {
    HapticFeedback.selectionClick();
    setState(() {
      _destPoiId = poi.id;
      if (poi.floorId != _floorId) _floorId = poi.floorId;
      _route = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitFloor();
      _focusNode(poi.nodeId);
    });
  }

  void _computeRoute() {
    final dest = _destPoiId == null ? null : VenueNavigation.poiById(_destPoiId!);
    if (dest == null) return;

    final startFloor = _startFloorId ?? _floorId;
    final startNode = _startNodeId ?? _defaultStartNode(startFloor);

    final result = VenuePathfinder.route(
      startFloorId: startFloor,
      startNodeId: startNode,
      endFloorId: dest.floorId,
      endNodeId: dest.nodeId,
    );

    if (result.isEmpty) {
      setState(() => _route = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find a route — try scanning a You Are Here QR')),
      );
      return;
    }

    // Stay on the start floor so the delegate sees the path from where they
    // are; the cross-floor note tells them when to switch floors.
    setState(() {
      _route = result;
      _floorId = startFloor;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToRoute());
  }

  void _fitToRoute() {
    final segment = _activeSegment;
    if (segment == null) return;
    final points = segment.nodeIds
        .map((id) => _floor.node(id))
        .whereType<VenueNode>()
        .map(_latLng)
        .toList();
    if (points.length < 2) {
      _fitFloor();
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(60, 140, 60, 220),
        maxZoom: 3,
      ),
    );
  }

  String _defaultStartNode(String floorId) {
    final f = VenueNavigation.floor(floorId);
    return f.pois
            .where((p) => p.category == VenuePoiCategory.entrance)
            .firstOrNull
            ?.nodeId ??
        f.nodes.first.id;
  }

  Future<void> _scanQr() async {
    final anchorId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _VenueQrScanner()),
    );
    if (anchorId == null || !mounted) return;
    final poi = VenueNavigation.poiByAnchor(anchorId);
    if (poi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown venue anchor: $anchorId')),
      );
      return;
    }
    _setYouAreHere(poi);
  }

  List<VenuePoi> get _visiblePois {
    final q = _query.trim().toLowerCase();
    final base = _floor.pois.where((p) => p.category != VenuePoiCategory.anchor).toList();
    if (q.isEmpty) return base;
    return base.where((p) {
      final blob = '${p.name} ${p.subtitle} ${p.keywords.join(' ')}'.toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  VenueRouteSegment? get _activeSegment {
    final r = _route;
    if (r == null) return null;
    for (final s in r.segments) {
      if (s.floorId == _floorId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dest = _destPoiId == null ? null : VenueNavigation.poiById(_destPoiId!);
    final segment = _activeSegment;
    final routePoints = segment == null
        ? <LatLng>[]
        : segment.nodeIds
            .map((id) => _floor.node(id))
            .whereType<VenueNode>()
            .map(_latLng)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                crs: const CrsSimple(),
                initialCenter: _rc.pixelToLatLng(x: venuePlanWidth / 2, y: venuePlanHeight / 2),
                initialZoom: 0,
                minZoom: -1,
                maxZoom: 4,
                cameraConstraint: CameraConstraint.containCenter(bounds: _rc.getMaxBounds()),
                onTap: (_, latlng) => FocusScope.of(context).unfocus(),
              ),
              children: [
                OverlayImageLayer(
                  overlayImages: [
                    OverlayImage(
                      bounds: _rc.getMaxBounds(),
                      imageProvider: AssetImage(_floor.image),
                      opacity: 1,
                    ),
                  ],
                ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 6,
                        color: AppColors.navy,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),
                MarkerLayer(markers: _buildMarkers(dest)),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      _CircleBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _startNodeId == null ? Icons.location_searching_rounded : Icons.my_location_rounded,
                                size: 18,
                                color: _startNodeId == null ? AppColors.inkSoft : AppColors.navy,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _startNodeId == null
                                      ? 'Scan QR or pick a start point'
                                      : 'You are here',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CircleBtn(icon: Icons.qr_code_scanner_rounded, onTap: _scanQr),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    children: VenueNavigation.floors.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Center(
                          child: NsePillChip(
                            label: f.shortTitle,
                            selected: _floorId == f.id,
                            onTap: () => _selectFloor(f.id),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.18,
            maxChildSize: 0.62,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: AppShadows.elevated,
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search auditorium, food, toilets…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                    ),
                    if (dest != null) ...[
                      const SizedBox(height: 12),
                      NseCard(
                        tint: AppColors.navySoft,
                        child: Row(
                          children: [
                            NseIconBadge(icon: dest.icon, size: 40),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dest.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w800)),
                                  Text(dest.subtitle, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _computeRoute,
                              icon: const Icon(Icons.directions_rounded, size: 18),
                              label: const Text('Go'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_route != null && !_route!.isEmpty) ...[
                      const SizedBox(height: 12),
                      if (_route!.crossFloorNote != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NseCard(
                            tint: AppColors.goldSoft,
                            child: Row(
                              children: [
                                const Icon(Icons.stairs_rounded, color: AppColors.gold),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _route!.crossFloorNote!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (segment != null)
                        ...VenuePathfinder.stepsForSegment(segment).map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.turn_right_rounded, size: 18, color: AppColors.navy),
                                const SizedBox(width: 8),
                                Expanded(child: Text(step, style: Theme.of(context).textTheme.bodyMedium)),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    Text('Places on ${_floor.shortTitle}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            )),
                    const SizedBox(height: 8),
                    ..._visiblePois.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NseListRow(
                            icon: p.icon,
                            title: p.name,
                            subtitle: p.subtitle,
                            trailing: _destPoiId == p.id
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.green)
                                : const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                            onTap: () => _selectDestination(p),
                          ),
                        )),
                    if (_startNodeId == null) ...[
                      const SizedBox(height: 8),
                      Text('Quick start',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.inkSoft)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _floor.pois
                            .where((p) => p.anchorId != null)
                            .map(
                              (p) => NsePillChip(
                                label: 'I\'m at ${p.name}',
                                selected: false,
                                subtle: true,
                                onTap: () => _setYouAreHere(p),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(VenuePoi? dest) {
    final markers = <Marker>[];

    for (final poi in _floor.pois) {
      if (poi.category == VenuePoiCategory.anchor && poi.id != _destPoiId) continue;
      final node = _floor.node(poi.nodeId);
      if (node == null) continue;

      final isDest = dest?.id == poi.id;
      final isHere = _startFloorId == _floorId && _startNodeId == poi.nodeId;

      markers.add(
        Marker(
          point: _latLng(node),
          width: isDest || isHere ? 52 : 44,
          height: isDest || isHere ? 58 : 50,
          child: GestureDetector(
            onTap: () => _selectDestination(poi),
            child: _PoiPin(
              icon: poi.icon,
              label: isHere ? 'You' : (isDest ? 'Go' : null),
              highlight: isDest,
              here: isHere,
            ),
          ),
        ),
      );
    }

    if (_startFloorId == _floorId && _startNodeId != null) {
      final already = markers.any((m) {
        final node = _floor.node(_startNodeId!);
        return node != null && m.point == _latLng(node);
      });
      if (!already) {
        final node = _floor.node(_startNodeId!);
        if (node != null) {
          markers.add(
            Marker(
              point: _latLng(node),
              width: 56,
              height: 56,
              child: const _YouAreHereDot(),
            ),
          );
        }
      }
    }

    return markers;
  }
}

class _PoiPin extends StatelessWidget {
  const _PoiPin({required this.icon, this.label, this.highlight = false, this.here = false});

  final IconData icon;
  final String? label;
  final bool highlight;
  final bool here;

  @override
  Widget build(BuildContext context) {
    final color = here ? AppColors.navy : (highlight ? AppColors.gold : AppColors.navy);
    final bg = here ? AppColors.navySoft : (highlight ? AppColors.goldSoft : AppColors.surface);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: here || highlight ? 2.5 : 1.2),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ],
    );
  }
}

class _YouAreHereDot extends StatelessWidget {
  const _YouAreHereDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: AppShadows.elevated,
      ),
      child: const Center(
        child: Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _VenueQrScanner extends StatefulWidget {
  const _VenueQrScanner();

  @override
  State<_VenueQrScanner> createState() => _VenueQrScannerState();
}

class _VenueQrScannerState extends State<_VenueQrScanner> {
  final _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handle(String raw) {
    if (_done) return;
    final anchor = VenueNavigation.parseAnchorFromQr(raw);
    if (anchor == null) return;
    _done = true;
    HapticFeedback.mediumImpact();
    _controller.stop();
    if (mounted) Navigator.pop(context, anchor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan You Are Here'),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  final raw = b.rawValue;
                  if (raw != null) _handle(raw);
                }
              },
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.ink,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Point at a venue QR sign. Format: nse-venue:gf_entrance',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
