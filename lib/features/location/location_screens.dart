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
  _HotelSort _sort = _HotelSort.ranked;
  int? _maxRate; // cheapest-rate ceiling in naira

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: ReferenceData.hotels(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'Hotels', subtitle: 'Official masterlist — ranked, nearest or cheapest.'),
              Expanded(child: LoadingView()),
            ]);
          }
          final all = snap.data!;
          final premier = all.where((h) => h.qualityTier == 'premier').length;
          final withPhotos = all.where((h) => h.photoCount > 0).length;

          var filtered = all
              .where((h) => _tierFilter == null || h.qualityTier == _tierFilter)
              .where((h) => _maxRate == null ||
              (h.minRate != null && h.minRate! <= _maxRate!) ||
              // "Rates pending" hotels stay visible under a price filter.
              (h.minRate == null && _maxRate != null))
              .toList();
          switch (_sort) {
            case _HotelSort.ranked:
              filtered.sort((a, b) => a.rank.compareTo(b.rank));
            case _HotelSort.nearest:
              filtered.sort((a, b) {
                final ad = a.distanceKm, bd = b.distanceKm;
                if (ad == null && bd == null) return a.rank.compareTo(b.rank);
                if (ad == null) return 1;
                if (bd == null) return -1;
                return ad.compareTo(bd);
              });
            case _HotelSort.cheapest:
              filtered.sort((a, b) {
                final ar = a.minRate, br = b.minRate;
                if (ar == null && br == null) return a.rank.compareTo(b.rank);
                if (ar == null) return 1;
                if (br == null) return -1;
                return ar.compareTo(br);
              });
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              NseTitleHeader(
                title: 'Hotels',
                subtitle: '${all.length} delegate hotels · $premier premier · $withPhotos with photos.',
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tierChip('All', null),
                    _tierChip('Premier', 'premier'),
                    _tierChip('Standard', 'standard'),
                    _tierChip('Value', 'value'),
                    const SizedBox(width: 8),
                    _sortChip('Ranked', _HotelSort.ranked, Icons.star_rounded),
                    _sortChip('Nearest', _HotelSort.nearest, Icons.near_me_rounded),
                    _sortChip('Cheapest', _HotelSort.cheapest, Icons.payments_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _priceChip('Any price', null),
                    _priceChip('≤ ₦20k', 20000),
                    _priceChip('≤ ₦35k', 35000),
                    _priceChip('≤ ₦60k', 60000),
                    _priceChip('≤ ₦100k', 100000),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...filtered.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RankedHotelCard(hotel: h),
                  )),
              if (filtered.isEmpty)
                const NseCard(
                  child: Text('No hotels match these filters. Try widening the price range.'),
                ),
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

  Widget _sortChip(String label, _HotelSort sort, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NsePillChip(
        label: label,
        selected: _sort == sort,
        subtle: true,
        onTap: () => setState(() => _sort = sort),
      ),
    );
  }

  Widget _priceChip(String label, int? maxRate) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NsePillChip(
        label: label,
        selected: _maxRate == maxRate,
        subtle: true,
        onTap: () => setState(() => _maxRate = maxRate),
      ),
    );
  }
}

enum _HotelSort { ranked, nearest, cheapest }

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
                      child: Text(sanitizeDisplay(hotel.name), style: Theme.of(context).textTheme.titleSmall),
                    ),
                    NseStatusChip(label: sanitizeDisplay(hotel.tierLabel), tone: _tierTone(hotel.qualityTier)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(sanitizeDisplay(hotel.tone), style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Text(
                  sanitizeDisplay(hotel.location),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (hotel.minRate != null)
                      NseStatusChip(
                        label: 'from ₦${_formatNaira(hotel.minRate!)}',
                        tone: AppColors.goldSoft,
                      ),
                    NseStatusChip(label: sanitizeDisplay(hotel.roomSummary), tone: AppColors.greenSoft),
                    if (hotel.distanceKm != null)
                      NseStatusChip(label: '${_formatKm(hotel.distanceKm!)} to venue', tone: AppColors.navySoft),
                  ],
                ),
                if (hotel.contactPhone != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _callHotel(context, hotel.contactPhone!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.call_rounded, size: 15, color: AppColors.green),
                            const SizedBox(width: 6),
                            Text(
                              sanitizeDisplay(hotel.contactPhone!),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _callHotel(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^+\d]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dial $phone')),
      );
    }
  }

  String _formatNaira(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _formatKm(double km) => km == km.roundToDouble()
      ? '${km.toStringAsFixed(0)} km'
      : '${km.toStringAsFixed(1)} km';

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
                    Text(sanitizeDisplay(info.conferenceTitle), textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(sanitizeDisplay(info.theme), textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              NseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sanitizeDisplay('${info.dates}\n${info.venue}'), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text('Chairman: ${sanitizeDisplay(info.chairman)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: info.stats
                    .map((s) => NseStatusChip(label: sanitizeDisplay('${s['value']} ${s['label']}'), tone: AppColors.greenSoft))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              const NseSectionTitle(title: 'Entertainment'),
              NseCard(child: Text(sanitizeDisplay(info.entertainment['focus'] ?? ''), style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(height: AppSpacing.md),
              const NseSectionTitle(title: 'Spouses programme'),
              NseCard(
                child: Text(
                  sanitizeDisplay('${info.spouses['venue']}\n${info.spouses['focus']}'),
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
                              Expanded(child: Text(sanitizeDisplay(d), style: Theme.of(context).textTheme.bodyMedium)),
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
                child: Text(sanitizeDisplay(pois['shuttle'] as String?), style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.sm),
              NseCard(
                child: Text(sanitizeDisplay(pois['parking'] as String?), style: Theme.of(context).textTheme.bodyMedium),
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

  static const _groupOrder = <String, List<String>>{
    'Airport & transport': ['Airport'],
    'Security & emergency': ['Security'],
    'Government & liaison': ['Government'],
    'Hospitals': ['Hospital'],
    'Culture & heritage': ['Culture'],
    'Food & essentials': ['Restaurant', 'Pharmacy', 'ATM', 'Shopping'],
    'Programme visits': ['Spouses visit'],
  };

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

          final groups = <String, List<Map<String, dynamic>>>{};
          for (final p in places) {
            final cat = p['category'] as String? ?? '';
            final group = _groupOrder.entries
                .firstWhere(
                  (g) => g.value.contains(cat),
                  orElse: () => const MapEntry('Other', <String>[]),
                )
                .key;
            (groups[group] ??= []).add(p);
          }

          Widget groupCards(List<Map<String, dynamic>> items) => Column(
                children: items
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NearbyCard(place: p, venueLat: vLat, venueLng: vLng),
                      ),
                    )
                    .toList(),
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              const NseTitleHeader(
                title: 'Nearby',
                subtitle: 'Maiduguri, Borno State · distances from ICC · tap for directions.',
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              for (final group in _groupOrder.keys)
                if (groups.containsKey(group)) ...[
                  NseSectionTitle(title: group),
                  groupCards(groups[group]!),
                  const SizedBox(height: AppSpacing.sm),
                ],
              if (groups.containsKey('Other')) ...[
                const NseSectionTitle(title: 'Other'),
                groupCards(groups['Other']!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.place, required this.venueLat, required this.venueLng});

  final Map<String, dynamic> place;
  final double venueLat;
  final double venueLng;

  @override
  Widget build(BuildContext context) {
    final lat = (place['latitude'] as num?)?.toDouble();
    final lng = (place['longitude'] as num?)?.toDouble();
    final km = lat != null && lng != null ? haversineKm(venueLat, venueLng, lat, lng) : null;
    final category = sanitizeDisplay(place['category'] as String?);

    return NseCard(
      padding: EdgeInsets.zero,
      onTap: () {
        final q = Uri.encodeComponent(
          (place['query'] as String?) ?? (place['name'] as String?) ?? '',
        );
        launchUrl(
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
          mode: LaunchMode.externalApplication,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place['image'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppSpacing.radius),
              ),
              child: CachedNetworkImage(
                imageUrl: place['image'] as String,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _categoryAvatar(category),
              ),
            )
          else
            _categoryAvatar(category),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sanitizeDisplay(place['name'] as String?), style: Theme.of(context).textTheme.titleSmall),
                  Text(sanitizeDisplay(place['note'] as String? ?? ''), style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      NseStatusChip(label: category, tone: _categoryTone(category)),
                      const SizedBox(width: 8),
                      Icon(Icons.straighten_rounded, size: 14, color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Text(km != null ? formatDistanceKm(km) : '—', style: Theme.of(context).textTheme.labelSmall),
                      const Text(' from ICC', style: TextStyle(fontSize: 11)),
                      if (place['phone'] != null) ...[
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _callPlace(context, place['phone'] as String),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.call_rounded, size: 15, color: AppColors.green),
                                const SizedBox(width: 6),
                                Text(
                                  'Call',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.green),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callPlace(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^+\d]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dial $phone')),
      );
    }
  }

  Widget _categoryAvatar(String category) {
    return Container(
      width: 96,
      height: 96,
      color: _categoryTone(category),
      alignment: Alignment.center,
      child: Icon(_categoryIcon(category), size: 32, color: _categoryInk(category)),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
        'Airport' => Icons.flight_land_rounded,
        'Security' => Icons.local_police_rounded,
        'Government' => Icons.account_balance_rounded,
        'Hospital' => Icons.local_hospital_rounded,
        'Culture' => Icons.museum_rounded,
        'Restaurant' => Icons.restaurant_rounded,
        'Pharmacy' => Icons.medication_rounded,
        'ATM' => Icons.payments_rounded,
        'Shopping' => Icons.shopping_bag_rounded,
        'Spouses visit' => Icons.tour_rounded,
        _ => Icons.place_rounded,
      };

  Color _categoryTone(String category) => switch (category) {
        'Hospital' => AppColors.destructiveSoft,
        'Government' || 'Pharmacy' => AppColors.greenSoft,
        'Culture' || 'Restaurant' || 'Shopping' || 'Spouses visit' => AppColors.goldSoft,
        _ => AppColors.navySoft,
      };

  Color _categoryInk(String category) => switch (category) {
        'Hospital' => AppColors.destructive,
        'Government' || 'Pharmacy' => AppColors.green,
        'Culture' || 'Restaurant' || 'Shopping' || 'Spouses visit' => AppColors.gold,
        _ => AppColors.navy,
      };
}
