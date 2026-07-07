import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/data/hotel_media.dart';
import 'package:nse_mobile/data/reference_data.dart';
import 'package:nse_mobile/data/transport_data.dart';
import 'package:nse_mobile/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AccommodationScreen extends ConsumerStatefulWidget {
  const AccommodationScreen({super.key});

  @override
  ConsumerState<AccommodationScreen> createState() => _AccommodationScreenState();
}

class _AccommodationScreenState extends ConsumerState<AccommodationScreen> {
  String? _tierFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: ReferenceData.hotels(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'Hotels', subtitle: 'Ranked by quality — premier first.'),
              Expanded(child: LoadingView()),
            ]);
          }
          final all = snap.data!;
          final filtered = _tierFilter == null
              ? all
              : all.where((h) => h.qualityTier == _tierFilter).toList();
          final premier = all.where((h) => h.qualityTier == 'premier').length;
          final withPhotos = all.where((h) => h.photoCount > 0).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              NseTitleHeader(
                title: 'Hotels',
                subtitle: '$premier premier properties · $withPhotos with inspection photos.',
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
              ),
              const SizedBox(height: 0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tierChip('All', null),
                    _tierChip('Premier', 'premier'),
                    _tierChip('Standard', 'standard'),
                    _tierChip('Value', 'value'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...filtered.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RankedHotelCard(hotel: h),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _tierChip(String label, String? tier) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NsePillChip(
        label: label,
        selected: _tierFilter == tier,
        subtle: true,
        onTap: () => setState(() => _tierFilter = tier),
      ),
    );
  }
}

class _RankedHotelCard extends StatelessWidget {
  const _RankedHotelCard({required this.hotel});

  final ReferenceHotel hotel;

  @override
  Widget build(BuildContext context) {
    final cover = hotel.images.isNotEmpty ? hotel.images.first : null;
    return NseCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/accommodation/${hotel.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cover != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radius)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: HotelPhoto(path: cover.preview),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: NseStatusChip(label: '#${hotel.rank}', tone: _tierTone(hotel.qualityTier)),
                  ),
                  if (hotel.photoCount > 1)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${hotel.photoCount} photos',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(hotel.name, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    NseStatusChip(label: hotel.tierLabel, tone: _tierTone(hotel.qualityTier)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(hotel.tone, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Text(
                  hotel.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    NseStatusChip(label: hotel.roomSummary, tone: AppColors.greenSoft),
                    NseStatusChip(label: hotel.rateStatus, tone: AppColors.navySoft),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _tierTone(String tier) => switch (tier) {
        'premier' => AppColors.goldSoft,
        'value' => AppColors.greenSoft,
        _ => AppColors.navySoft,
      };
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: ReferenceData.conferenceInfo(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'About NSE', subtitle: 'Conference identity and context.'),
              Expanded(child: LoadingView()),
            ]);
          }
          final info = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              const NseTitleHeader(
                title: 'About NSE',
                subtitle: 'Conference identity and context.',
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              NseCard(
                tint: AppColors.cream,
                child: Column(
                  children: [
                    const NseBrandMark(height: 56),
                    const SizedBox(height: 12),
                    Text(info.conferenceTitle, textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(info.theme, textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              NseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${info.dates}\n${info.venue}', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text('Chairman: ${info.chairman}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: info.stats
                    .map((s) => NseStatusChip(label: '${s['value']} ${s['label']}', tone: AppColors.greenSoft))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              const NseSectionTitle(title: 'Entertainment'),
              NseCard(child: Text(info.entertainment['focus'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(height: AppSpacing.md),
              const NseSectionTitle(title: 'Spouses programme'),
              NseCard(
                child: Text(
                  '${info.spouses['venue']}\n${info.spouses['focus']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => launchUrl(Uri.parse(info.officialSite), mode: LaunchMode.externalApplication),
                child: const Text('Visit nse.org.ng'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DirectionsScreen extends StatelessWidget {
  const DirectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: ReferenceData.maiduguriPois(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'Directions'),
              Expanded(child: LoadingView()),
            ]);
          }
          final pois = snap.data!;
          final directions = (pois['directions'] as List).cast<String>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              const NseTitleHeader(
                title: 'Directions',
                subtitle: 'International Conference Centre · Maiduguri, Borno State',
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              const NseSectionTitle(title: 'Getting here'),
              NseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: directions
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.directions_rounded, size: 18, color: AppColors.navy),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(d, style: Theme.of(context).textTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              NseCard(
                tint: AppColors.greenSoft,
                child: Text(pois['shuttle'] as String, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.sm),
              NseCard(
                child: Text(pois['parking'] as String, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://www.google.com/maps/dir/?api=1&destination=11.8333,13.15'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Open turn-by-turn in Maps'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: ReferenceData.maiduguriPois(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'Nearby'),
              Expanded(child: LoadingView()),
            ]);
          }
          final pois = snap.data!;
          final venue = pois['venue'] as Map<String, dynamic>? ?? {};
          final vLat = (venue['latitude'] as num?)?.toDouble() ?? 11.8333;
          final vLng = (venue['longitude'] as num?)?.toDouble() ?? 13.15;
          final places = (pois['nearby'] as List).cast<Map<String, dynamic>>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              const NseTitleHeader(
                title: 'Nearby',
                subtitle: 'Distances from ICC Maiduguri · tap for directions.',
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              ...places.map((p) {
                final lat = (p['latitude'] as num?)?.toDouble();
                final lng = (p['longitude'] as num?)?.toDouble();
                final listedKm = (p['distanceKm'] as num?)?.toDouble();
                final computedKm = lat != null && lng != null
                    ? haversineKm(vLat, vLng, lat, lng)
                    : listedKm;
                final distanceLabel = computedKm != null
                    ? formatDistanceKm(computedKm)
                    : (p['distance'] as String? ?? '');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NseCard(
                    padding: EdgeInsets.zero,
                    onTap: () {
                      final q = Uri.encodeComponent(p['query'] as String);
                      launchUrl(
                        Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p['image'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(AppSpacing.radius),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: p['image'] as String,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                width: 96,
                                height: 96,
                                color: AppColors.navySoft,
                                child: const Icon(Icons.place_rounded),
                              ),
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    NseStatusChip(label: p['category'] as String, tone: AppColors.navySoft),
                                    const SizedBox(width: 8),
                                    Icon(Icons.straighten_rounded, size: 14, color: Theme.of(context).hintColor),
                                    const SizedBox(width: 4),
                                    Text(distanceLabel, style: Theme.of(context).textTheme.labelSmall),
                                    const Text(' from ICC', style: TextStyle(fontSize: 11)),
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
        },
      ),
    );
  }
}
