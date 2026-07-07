import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/data/reference_data.dart';
import 'package:nse_mobile/data/transport_data.dart';
import 'package:nse_mobile/features/map/venue_screens.dart';
import 'package:nse_mobile/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.room});

  final String? room;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _pois;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    ReferenceData.maiduguriPois().then((p) {
      if (mounted) setState(() => _pois = p);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: NseTitleHeader(
              title: 'Venue & map',
              subtitle: '3D tour, ICC floor plans, and nearby places.',
              onBack: () => context.pop(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Venue'),
                Tab(text: 'Outdoor'),
                Tab(text: 'Nearby'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                const VenueTab(),
                _OutdoorMap(pois: _pois),
                _NearbyMapTab(pois: _pois),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutdoorMap extends StatelessWidget {
  const _OutdoorMap({this.pois});

  final Map<String, dynamic>? pois;

  @override
  Widget build(BuildContext context) {
    final venue = pois?['venue'] as Map<String, dynamic>? ?? {};
    final vLat = (venue['latitude'] as num?)?.toDouble() ?? EventConfig.venueLatitude;
    final vLng = (venue['longitude'] as num?)?.toDouble() ?? EventConfig.venueLongitude;

    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(vLat, vLng), zoom: 14),
            markers: {
              Marker(
                markerId: const MarkerId('venue'),
                position: LatLng(vLat, vLng),
                infoWindow: InfoWindow(
                  title: EventConfig.venueName,
                  snippet: EventConfig.venueAddress,
                ),
              ),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: NseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(EventConfig.venueName, style: Theme.of(context).textTheme.titleSmall),
                Text(EventConfig.venueAddress, style: Theme.of(context).textTheme.bodySmall),
                if (pois?['shuttle'] != null) ...[
                  const SizedBox(height: 8),
                  Text(pois!['shuttle'] as String, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NearbyMapTab extends StatelessWidget {
  const _NearbyMapTab({this.pois});

  final Map<String, dynamic>? pois;

  @override
  Widget build(BuildContext context) {
    if (pois == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final venue = pois!['venue'] as Map<String, dynamic>? ?? {};
    final vLat = (venue['latitude'] as num?)?.toDouble() ?? EventConfig.venueLatitude;
    final vLng = (venue['longitude'] as num?)?.toDouble() ?? EventConfig.venueLongitude;
    final places = (pois!['nearby'] as List).cast<Map<String, dynamic>>();

    final markers = <Marker>{
      const Marker(
        markerId: MarkerId('icc'),
        position: LatLng(EventConfig.venueLatitude, EventConfig.venueLongitude),
        infoWindow: InfoWindow(title: 'ICC Maiduguri', snippet: 'Conference venue'),
      ),
      ...places.map((p) {
        final lat = (p['latitude'] as num?)?.toDouble();
        final lng = (p['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        final km = haversineKm(vLat, vLng, lat, lng);
        return Marker(
          markerId: MarkerId(p['id'] as String? ?? p['name'] as String),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: p['name'] as String,
            snippet: '${formatDistanceKm(km)} from ICC',
          ),
        );
      }).whereType<Marker>(),
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(vLat, vLng), zoom: 13),
              markers: markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        NseCard(
          tint: AppColors.cream,
          child: Text(
            'Straight-line distance from ICC to each point. Tap for turn-by-turn directions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...places.map((p) {
          final lat = (p['latitude'] as num?)?.toDouble();
          final lng = (p['longitude'] as num?)?.toDouble();
          final km = lat != null && lng != null ? haversineKm(vLat, vLng, lat, lng) : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NseCard(
              padding: EdgeInsets.zero,
              onTap: () {
                final q = Uri.encodeComponent(p['query'] as String);
                launchUrl(
                  Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Row(
                children: [
                  if (p['image'] != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppSpacing.radius),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: p['image'] as String,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] as String, style: Theme.of(context).textTheme.titleSmall),
                          Text(p['note'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              NseStatusChip(label: p['category'] as String, tone: AppColors.navySoft),
                              const SizedBox(width: 8),
                              if (km != null)
                                Text(
                                  '${formatDistanceKm(km)} from ICC',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

