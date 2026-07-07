import 'package:flutter/material.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/data/hotel_media.dart';
import 'package:nse_mobile/data/reference_data.dart';
import 'package:nse_mobile/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReferenceHotel?>(
      future: ReferenceData.hotelById(widget.hotelId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: NseLoadingBlock(lines: 6),
            ),
          );
        }
        final hotel = snap.data;
        if (hotel == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const NseEmptyState(
              title: 'Hotel not found',
              body: 'This hotel is no longer available.',
              icon: Icons.hotel_rounded,
            ),
          );
        }
        final hasImages = hotel.images.isNotEmpty;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              if (hasImages)
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  title: Text(hotel.shortName),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          itemCount: hotel.images.length,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (i) => setState(() => _photoIndex = i),
                          itemBuilder: (context, i) {
                            final img = hotel.images[i];
                            return GestureDetector(
                              onTap: () => _openGallery(context, hotel, i),
                              child: HotelPhoto(path: img.preview),
                            );
                          },
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black26, Colors.transparent, Colors.black54],
                              stops: [0, 0.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Row(
                            children: List.generate(
                              hotel.images.length,
                              (i) => Container(
                                width: i == _photoIndex ? 18 : 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: i == _photoIndex ? 0.95 : 0.5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: GestureDetector(
                            onTap: () => _openGallery(context, hotel, _photoIndex),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${hotel.images.length} photos',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverAppBar(pinned: true, title: Text(hotel.shortName)),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
              if (!hasImages) ...[
                NseCard(
                  tint: AppColors.cream,
                  child: Row(
                    children: [
                      const Icon(Icons.image_not_supported_rounded, color: AppColors.muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Photos for this property are coming soon.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  NseStatusChip(
                    label: '#${hotel.rank} · ${hotel.tierLabel}',
                    tone: _tierTone(hotel.qualityTier),
                  ),
                  const SizedBox(width: 8),
                  NseStatusChip(label: hotel.tone, tone: AppColors.navySoft),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(hotel.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(hotel.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              NseCard(
                child: Column(
                  children: [
                    _factRow(context, 'Rooms', hotel.roomSummary),
                    _factRow(context, 'Rates', hotel.rateStatus),
                    _factRow(context, 'Venue route', hotel.distanceToVenue),
                    _factRow(context, 'Location', hotel.location),
                  ],
                ),
              ),
              if (hotel.highlights.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const NseSectionTitle(title: 'Highlights'),
                ...hotel.highlights.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(h, style: Theme.of(context).textTheme.bodySmall)),
                      ],
                    ),
                  ),
                ),
              ],
              if (hotel.rooms.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const NseSectionTitle(title: 'Room rates'),
                NseCard(
                  child: Column(
                    children: hotel.rooms
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text(r['label'] ?? '')),
                                Text(r['rate'] ?? '', style: Theme.of(context).textTheme.labelLarge),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (hotel.contactPhone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:${hotel.contactPhone}')),
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text('Call'),
                      ),
                    ),
                  if (hotel.contactPhone != null) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final q = Uri.encodeComponent('${hotel.name}, ${hotel.location}');
                        launchUrl(
                          Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Maps'),
                    ),
                  ),
                ],
              ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _factRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: Theme.of(context).textTheme.labelSmall)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Color _tierTone(String tier) => switch (tier) {
        'premier' => AppColors.goldSoft,
        'value' => AppColors.greenSoft,
        _ => AppColors.navySoft,
      };

  void _openGallery(BuildContext context, ReferenceHotel hotel, int initial) {
    NseBottomSheet.show<void>(
      context,
      title: hotel.name,
      subtitle: '${hotel.photoCount} inspection photos',
      scrollControlled: true,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: hotel.images.length,
          itemBuilder: (_, i) {
            final img = hotel.images[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                child: HotelPhoto(path: img.preview, height: 240),
              ),
            );
          },
        ),
      ),
    );
  }
}
