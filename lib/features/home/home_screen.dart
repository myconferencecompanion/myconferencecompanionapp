import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/db_query.dart';
import 'package:nse_mobile/core/format.dart';
import 'package:nse_mobile/core/refresh_signals.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final client = ref.read(supabaseProvider);
    setState(() {
      _future = dbWait([
        client.from('announcements').select().order('created_at', ascending: false).limit(1),
      ]);
    });
  }

  static const _tools = [
    (Icons.calendar_month_rounded, 'Schedule', '/schedule', AppColors.navy, AppColors.navySoft),
    (Icons.room_service_rounded, 'Concierge', '/concierge', AppColors.gold, AppColors.goldSoft),
    (Icons.groups_rounded, 'Network', '/network', AppColors.green, AppColors.greenSoft),
    (Icons.hotel_rounded, 'Hotels', '/accommodation', AppColors.gold, AppColors.goldSoft),
    (Icons.explore_rounded, 'Maiduguri', '/maidguide', AppColors.navy, AppColors.navySoft),
    (Icons.map_rounded, 'Venue map', '/map', AppColors.green, AppColors.greenSoft),
    (Icons.campaign_rounded, 'Updates', '/announcements', AppColors.navy, AppColors.navySoft),
    (Icons.health_and_safety_rounded, 'Emergency', '/emergency', AppColors.destructive, AppColors.destructiveSoft),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(homeRefreshProvider, (prev, next) => _load());
    final auth = ref.watch(authProvider);
    final firstName = greetingFirstName(auth.displayName);

    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final announcements = (snap.data?[0] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        final announcement = announcements.isNotEmpty ? announcements.first : null;

        return RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppColors.navy,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverToBoxAdapter(
              child: NseHeroHeader(
                greeting: firstName,
                subtitle: 'GOOD DAY',
                trailing: const _CountdownPill(),
                bottom: NseSearchBar(onTap: () => context.push('/search')),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: loading
                    ? const NseLoadingBlock(lines: 3)
                    : _LatestAnnouncementCard(
                        title: announcement?['title'] as String? ?? 'No updates yet',
                        body: announcement?['body'] as String? ??
                            'Conference announcements will appear here first.',
                        onTap: () => context.push('/announcements'),
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: Text('QUICK ACTIONS', style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: AppShadows.card,
                  ),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.82,
                    children: [
                      for (final t in _tools)
                        _QuickTile(
                          icon: t.$1,
                          label: t.$2,
                          accent: t.$4,
                          accentSoft: t.$5,
                          onTap: () => context.push(t.$3),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _ConciergeCta(onTap: () => context.push('/concierge')),
              ),
            ),
          ],
          ),
        );
      },
    );
  }
}

/// Warm concierge prompt at the foot of the dashboard.
class _ConciergeCta extends StatelessWidget {
  const _ConciergeCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NseCard(
      onTap: onTap,
      tint: AppColors.greenSoft,
      child: Row(
        children: [
          const NseIconBadge(
            icon: Icons.support_agent_rounded,
            tone: Color(0x33123F2A),
            iconColor: AppColors.green,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need anything?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Call an usher, order a meal, or send an errand.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.green),
        ],
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            EventConfig.countdownLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact bank-style quick action: small icon disc with a label beneath.
class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      scale: 0.94,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _LatestAnnouncementCard extends StatelessWidget {
  const _LatestAnnouncementCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NseCard(
      onTap: onTap,
      tint: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NseIconBadge(
                icon: Icons.campaign_rounded,
                tone: AppColors.navySoft,
                iconColor: AppColors.navy,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest announcement',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.inkSoft.withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
