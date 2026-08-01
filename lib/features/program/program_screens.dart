import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/refresh_signals.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/format.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/data/venue_rooms.dart';
import 'package:nse_mobile/theme/app_theme.dart';

/// (foreground, background) tone for a session track.
(Color, Color) _trackTone(String? track) {
  switch (track) {
    case 'Technical':
      return (AppColors.navy, AppColors.navySoft);
    case 'Professional':
      return (AppColors.green, AppColors.greenSoft);
    case 'Social':
      return (AppColors.gold, AppColors.goldSoft);
    case 'Plenary':
      return (AppColors.green, AppColors.greenSoft);
    default:
      return (AppColors.navy, AppColors.navySoft);
  }
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _day = 1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: NseTitleHeader(
              title: 'Schedule',
              subtitle: 'Sessions, tracks, and the people on stage.',
              onBack: () => context.pop(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Sessions'), Tab(text: 'Speakers')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
          FutureBuilder(
            key: ValueKey(_day),
            future: client
                .from('sessions')
                .select('*, session_speakers(speakers(id,name,avatar_url))')
                .eq('day', _day)
                .order('starts_at'),
            builder: (context, snap) {
              if (!snap.hasData) return const LoadingView();
              final filtered = (snap.data as List).cast<Map<String, dynamic>>();

              final dayLabel = conferenceDays
                      .where((d) => d.day == _day)
                      .map((d) => d.label)
                      .firstOrNull ??
                  'Day $_day';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                          child: NseCard(
                            tint: AppColors.navySoft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const NseIconBadge(
                                      icon: Icons.view_day_rounded,
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
                                            dayLabel.toUpperCase(),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: AppColors.inkSoft,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.6,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${filtered.length} session${filtered.length == 1 ? '' : 's'} today',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.schedule_rounded, color: AppColors.navy),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  height: 52,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.zero,
                                    itemCount: conferenceDays.length,
                                    separatorBuilder: (_, i) => const SizedBox(width: 8),
                                    itemBuilder: (context, i) {
                                      final d = conferenceDays[i];
                                      return Center(
                                        child: NsePillChip(
                                          label: d.label,
                                          selected: _day == d.day,
                                          onTap: () => setState(() => _day = d.day),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: NseEmptyState(
                              title: 'No sessions',
                              body: 'Sessions for this day and track will appear here.',
                              icon: Icons.event_busy_rounded,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                            itemCount: filtered.length + 1,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              if (i == filtered.length) {
                                return const _DayFooter();
                              }
                              final s = filtered[i];
                              final start = parseIso(s['starts_at'] as String?);
                              final end = parseIso(s['ends_at'] as String?);
                              final track = s['track'] as String?;
                              final tone = _trackTone(track);
                              final speakers = (s['session_speakers'] as List? ?? [])
                                  .map((e) => (e as Map)['speakers'] as Map<String, dynamic>?)
                                  .whereType<Map<String, dynamic>>()
                                  .toList();
                              return NseCard(
                                onTap: () => context.push('/schedule/${s['id']}'),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    NseTimeBlock(
                                      start: start != null ? formatTime(start) : '—',
                                      end: end != null ? formatTime(end) : null,
                                      tone: tone.$2,
                                      color: tone.$1,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (track != null) ...[
                                            NseStatusChip(
                                              label: track,
                                              tone: tone.$2,
                                              textColor: tone.$1,
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          Text(
                                            sanitizeDisplay(s['title'] as String),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.place_rounded, size: 13, color: AppColors.inkSoft),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  (s['room'] as String?)?.trim().isNotEmpty == true
                                                      ? s['room'] as String
                                                      : 'Venue TBC',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (speakers.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            _SpeakerStack(speakers: speakers),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
                const SpeakersListScreen(embed: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakerStack extends StatelessWidget {
  const _SpeakerStack({required this.speakers});
  final List<Map<String, dynamic>> speakers;

  @override
  Widget build(BuildContext context) {
    final show = speakers.take(3).toList();
    const size = 26.0;
    return SizedBox(
      width: size + (show.length - 1) * 16,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: AppColors.surface, width: 2)),
                ),
                child: NseAvatar(
                  name: sanitizeDisplay(show[i]['name'] as String?),
                  imageUrl: show[i]['avatar_url'] as String?,
                  radius: size / 2 - 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Friendly footer that closes out a day's programme (fills empty space).
class _DayFooter extends StatelessWidget {
  const _DayFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.green),
          ),
          const SizedBox(height: 10),
          Text(
            "That's the full programme for this day",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    final userId = ref.watch(authProvider).userId;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppColors.ink),
      body: FutureBuilder(
        future: client
            .from('sessions')
            .select('*, session_speakers(speakers(*))')
            .eq('id', sessionId)
            .maybeSingle(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final s = snap.data as Map<String, dynamic>?;
          if (s == null) return const ErrorView(message: 'Session not found');
          final start = parseIso(s['starts_at'] as String?);
          final end = parseIso(s['ends_at'] as String?);
          final speakers = (s['session_speakers'] as List? ?? [])
              .map((e) => (e as Map)['speakers'] as Map<String, dynamic>?)
              .whereType<Map<String, dynamic>>()
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
            children: [
              _DetailHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s['track'] != null)
                      _HeroPill(label: s['track'] as String),
                    if (s['track'] != null) const SizedBox(height: 12),
                    Text(
                      sanitizeDisplay(s['title'] as String),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                    ),
                    if (start != null && end != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            formatTimeRange(start, end),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (s['room'] != null) ...[
                const SizedBox(height: AppSpacing.sm),
                NseCard(
                  onTap: () => context.push('/map?room=${Uri.encodeComponent(s['room'] as String)}'),
                  child: NseListRow(
                    icon: Icons.map_rounded,
                    title: hotspotNameForRoom(s['room'] as String?) ?? s['room'] as String,
                    subtitle: 'Open venue map',
                    onTap: () => context.push('/map?room=${Uri.encodeComponent(s['room'] as String)}'),
                  ),
                ),
              ],
              if (s['description'] != null) ...[
                const SizedBox(height: AppSpacing.md),
                const NseSectionTitle(title: 'About this session'),
                NseCard(child: Text(s['description'] as String, style: Theme.of(context).textTheme.bodyMedium)),
              ],
              if (speakers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const NseSectionTitle(title: 'Speakers'),
                NseGroupedList(
                  children: speakers
                      .map(
                        (sp) => NseListRow(
                          icon: Icons.mic_rounded,
                          title: sanitizeDisplay(sp['name'] as String),
                          subtitle: sanitizeDisplay(sp['title'] as String? ?? ''),
                          onTap: () => context.push('/speakers/${sp['id']}'),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (userId != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    await client.from('my_agenda').upsert({
                      'user_id': userId,
                      'session_id': sessionId,
                    });
                    bumpHome(ref);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to your agenda'),
                          action: SnackBarAction(
                            label: 'View',
                            onPressed: () => context.push('/agenda'),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark_add_rounded),
                  label: const Text('Add to my agenda'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class SpeakersListScreen extends ConsumerWidget {
  const SpeakersListScreen({super.key, this.embed = false});
  final bool embed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    final body = FutureBuilder(
      future: client.from('speakers').select().order('is_keynote', ascending: false),
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        final speakers = (snap.data as List).cast<Map<String, dynamic>>();
        if (speakers.isEmpty) {
          return const NseEmptyState(
            title: 'No speakers yet',
            body: 'Speaker profiles will appear here once published.',
            icon: Icons.mic_none_rounded,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: speakers.length,
          itemBuilder: (context, i) {
            final sp = speakers[i];
            final isKeynote = sp['is_keynote'] == true;
            return NseCard(
              onTap: () => context.push('/speakers/${sp['id']}'),
              padding: const EdgeInsets.all(14),
              tint: isKeynote ? AppColors.goldSoft : AppColors.surface,
              child: Column(
                children: [
                  NseAvatar(
                    name: sanitizeDisplay(sp['name'] as String?),
                    imageUrl: sp['avatar_url'] as String?,
                    radius: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sanitizeDisplay(sp['name'] as String),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sp['title'] != null)
                    Text(
                      sanitizeDisplay(sp['title'] as String),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isKeynote) ...[
                    const Spacer(),
                    const NseStatusChip(label: 'Keynote', tone: AppColors.goldSoft),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    if (embed) return body;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Column(
        children: [
          const NseTitleHeader(
            title: 'Speakers',
            subtitle: 'Keynotes and session leaders.',
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class SpeakerDetailScreen extends ConsumerWidget {
  const SpeakerDetailScreen({super.key, required this.speakerId});
  final String speakerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppColors.ink),
      body: FutureBuilder(
        future: client
            .from('speakers')
            .select('*, session_speakers(sessions(*))')
            .eq('id', speakerId)
            .maybeSingle(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final sp = snap.data as Map<String, dynamic>?;
          if (sp == null) return const ErrorView(message: 'Speaker not found');
          final sessions = (sp['session_speakers'] as List? ?? [])
              .map((e) => (e as Map)['sessions'] as Map<String, dynamic>?)
              .whereType<Map<String, dynamic>>()
              .toList();
          final isKeynote = sp['is_keynote'] == true;

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
            children: [
              _DetailHero(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: NseAvatar(
                        name: sanitizeDisplay(sp['name'] as String?),
                        imageUrl: sp['avatar_url'] as String?,
                        radius: 42,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isKeynote) ...[
                      const _HeroPill(label: 'KEYNOTE SPEAKER'),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      sanitizeDisplay(sp['name'] as String),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (sp['title'] != null)
                      Text(
                        sanitizeDisplay(sp['title'] as String),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    if (sp['company'] != null)
                      Text(
                        sp['company'] as String,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      ),
                  ],
                ),
              ),
              if (sp['bio'] != null) ...[
                const SizedBox(height: AppSpacing.md),
                const NseSectionTitle(title: 'Biography'),
                NseCard(child: Text(sp['bio'] as String, style: Theme.of(context).textTheme.bodyMedium)),
              ],
              if (sessions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const NseSectionTitle(title: 'Sessions'),
                NseGroupedList(
                  children: sessions
                      .map(
                        (s) => NseListRow(
                          icon: Icons.event_rounded,
                          title: sanitizeDisplay(s['title'] as String),
                          onTap: () => context.push('/schedule/${s['id']}'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Gradient hero panel used at the top of pushed detail screens.
class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.elevated,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.heroSheen,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class MyAgendaScreen extends ConsumerWidget {
  const MyAgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).userId;
    if (userId == null) {
      return const Scaffold(body: ErrorView(message: 'Sign in to view your agenda'));
    }

    final client = ref.watch(supabaseProvider);
    final tick = ref.watch(homeRefreshProvider);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        key: ValueKey(tick),
        future: () async {
          final agenda = await client.from('my_agenda').select().eq('user_id', userId);
          final ids = (agenda as List).map((a) => a['session_id'] as String).toList();
          if (ids.isEmpty) return <Map<String, dynamic>>[];
          final sessions = await client.from('sessions').select().order('starts_at');
          return (sessions as List)
              .cast<Map<String, dynamic>>()
              .where((s) => ids.contains(s['id']))
              .toList();
        }(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final sessions = snap.data!;
          if (sessions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: NseEmptyState(
                title: 'No saved sessions',
                body: 'Bookmark sessions from the schedule to build your personal programme.',
                icon: Icons.bookmark_border_rounded,
                action: FilledButton(
                  onPressed: () => context.push('/schedule'),
                  child: const Text('Browse schedule'),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => bumpHome(ref),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              itemCount: sessions.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return NseTitleHeader(
                    title: 'My agenda',
                    subtitle: '${sessions.length} saved session${sessions.length == 1 ? '' : 's'}.',
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  );
                }
                final s = sessions[i - 1];
                final start = parseIso(s['starts_at'] as String?);
                final end = parseIso(s['ends_at'] as String?);
                return NseCard(
                  onTap: () => context.push('/schedule/${s['id']}'),
                  child: Row(
                    children: [
                      const NseIconBadge(
                        icon: Icons.bookmark_rounded,
                        tone: AppColors.goldSoft,
                        iconColor: AppColors.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (start != null && end != null)
                              Text(
                                formatTimeRange(start, end),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.navy),
                              ),
                            Text(sanitizeDisplay(s['title'] as String), style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              [hotspotNameForRoom(s['room'] as String?), s['track']]
                                  .whereType<String>()
                                  .join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
