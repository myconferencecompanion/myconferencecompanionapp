import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/data/venue_plans.dart';
import 'package:nse_mobile/features/map/venue_indoor_map_screen.dart';
import 'package:nse_mobile/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

/// The venue experience: live indoor navigation, a 3D tour, and floor plans.
class VenueTab extends StatelessWidget {
  const VenueTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 40),
      children: [
        const _NavigateCard(),
        const SizedBox(height: 12),
        const _VenueTourCard(),
        const SizedBox(height: AppSpacing.lg),
        const NseSectionTitle(
          title: 'Floor plans',
          subtitle: 'Official architectural drawings — tap to zoom.',
        ),
        ...VenueAssets.plans.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(plan: p),
            )),
      ],
    );
  }
}

class _NavigateCard extends StatelessWidget {
  const _NavigateCard();

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VenueIndoorMapScreen()),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppShadows.elevated,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.navySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore_rounded, color: AppColors.navy, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Navigate the venue',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('LIVE',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Interactive floor map · search rooms · scan a QR to find your way.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueTourCard extends StatelessWidget {
  const _VenueTourCard();

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VenueTourScreen()),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppShadows.elevated,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take the 3D tour',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fly through the International Conference Centre before you arrive.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final VenuePlan plan;

  @override
  Widget build(BuildContext context) {
    return NseCard(
      padding: EdgeInsets.zero,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => FloorPlanViewer(plan: plan)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radius)),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: AppColors.paper,
                    child: Image.asset(plan.thumb, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Tap to zoom',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
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
                    NseIconBadge(icon: plan.icon, size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          Text(plan.subtitle, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: plan.highlights
                      .map((h) => NseStatusChip(label: h, tone: AppColors.navySoft, textColor: AppColors.navy))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen pinch-zoom viewer for a bundled floor plan.
class FloorPlanViewer extends StatelessWidget {
  const FloorPlanViewer({super.key, required this.plan});

  final VenuePlan plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(plan.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    )),
            Text('Pinch to zoom · drag to pan',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white60)),
          ],
        ),
      ),
      body: InteractiveViewer(
        maxScale: 6,
        minScale: 0.8,
        boundaryMargin: const EdgeInsets.all(80),
        child: Center(
          child: Image.asset(plan.image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Full-screen 3D venue tour video with tap-to-play/pause.
class VenueTourScreen extends StatefulWidget {
  const VenueTourScreen({super.key});

  @override
  State<VenueTourScreen> createState() => _VenueTourScreenState();
}

class _VenueTourScreenState extends State<VenueTourScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(VenueAssets.tourVideo)
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _error = true);
      });
    _controller.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playing = _controller.value.isPlaying;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('3D venue tour'),
      ),
      body: Center(
        child: _error
            ? const NseEmptyState(
                title: 'Tour unavailable',
                body: 'The venue tour video could not be loaded.',
                icon: Icons.videocam_off_rounded,
              )
            : !_ready
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: _togglePlay,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        AnimatedOpacity(
                          opacity: playing ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 46),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppColors.gold,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
