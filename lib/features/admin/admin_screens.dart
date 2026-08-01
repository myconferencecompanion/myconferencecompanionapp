import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/admin_config.dart';
import 'package:nse_mobile/core/db_query.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class AdminGate extends ConsumerWidget {
  const AdminGate({
    super.key,
    required this.requiredRoles,
    required this.child,
  });

  final List<String> requiredRoles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.canAccessAdmin) {
      return const Scaffold(body: ErrorView(message: 'Staff access required'));
    }
    if (!auth.hasAnyAdminRole(requiredRoles)) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorView(message: 'You do not have access to this section'),
      );
    }
    return child;
  }
}

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.canAccessAdmin) {
      return const Scaffold(body: ErrorView(message: 'Staff access required'));
    }

    final client = ref.watch(supabaseProvider);
    final isSuper = auth.roles.contains('super_admin');
    final badges = staffRoleBadges(auth.roles);
    final visibleSections = adminSections
        .where((s) => isSuper || auth.hasAnyAdminRole(s.roles))
        .toList();

    return Scaffold(
      body: FutureBuilder(
        future: dbWait([
          client.from('sessions').select('id'),
          client.from('speakers').select('id'),
          client.from('accommodations').select('id'),
          client.from('emergency_contacts').select('id'),
          client.from('announcements').select('id'),
          client.from('profiles').select('id'),
          client.from('menu_items').select('id'),
          client.from('food_orders').select('id').inFilter('status', ['pending', 'preparing', 'ready']),
          client.from('usher_requests').select('id').inFilter('status', ['pending', 'acknowledged']),
          client.from('errand_requests').select('id').inFilter('status', ['requested', 'accepted', 'in_progress']),
        ]),
        builder: (context, snap) {
          final counts = <String, int>{};
          if (snap.hasData) {
            final keys = [
              'sessions',
              'speakers',
              'accommodations',
              'emergency',
              'announcements',
              'attendees',
              'menu',
              'openOrders',
              'openUshers',
              'openErrands',
            ];
            for (var i = 0; i < keys.length; i++) {
              counts[keys[i]] = (snap.data![i] as List).length;
            }
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(gradient: AppTheme.brandGradient),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              ),
                              Expanded(
                                child: Text(
                                  'Admin',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badges.isEmpty
                                ? 'Manage conference operations'
                                : 'Signed in as ${badges.join(' · ')}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          if (isSuper) ...[
                            const SizedBox(height: AppSpacing.md),
                            NseCard(
                              tint: Colors.white.withValues(alpha: 0.12),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const Icon(Icons.groups_rounded, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${counts['attendees'] ?? '—'}',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        Text(
                                          'Total delegates',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/admin/delegates'),
                                    child: const Text('View', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (snap.hasData)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AdminStatChip(
                          label: 'Orders',
                          count: counts['openOrders'] ?? 0,
                          icon: Icons.restaurant_rounded,
                          tone: AppColors.goldSoft,
                          iconColor: AppColors.gold,
                          onTap: () => context.push('/admin/orders'),
                        ),
                        _AdminStatChip(
                          label: 'Ushers',
                          count: counts['openUshers'] ?? 0,
                          icon: Icons.support_agent_rounded,
                          tone: AppColors.navySoft,
                          iconColor: AppColors.navy,
                          onTap: () => context.push('/admin/ushers'),
                        ),
                        _AdminStatChip(
                          label: 'Errands',
                          count: counts['openErrands'] ?? 0,
                          icon: Icons.local_laundry_service_rounded,
                          tone: AppColors.greenSoft,
                          iconColor: AppColors.green,
                          onTap: () => context.push('/admin/errands'),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final section = visibleSections[index];
                      final sectionTools = section.tools
                          .where((t) => isSuper || auth.hasAnyAdminRole(t.roles))
                          .toList();
                      if (sectionTools.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: EdgeInsets.only(bottom: index == visibleSections.length - 1 ? 0 : AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NseSectionTitle(title: section.title, subtitle: section.subtitle),
                            const SizedBox(height: AppSpacing.sm),
                            ...sectionTools.map((tool) {
                              final count = tool.countKey != null ? counts[tool.countKey] : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: NseCard(
                                  onTap: () => context.push(tool.route),
                                  child: Row(
                                    children: [
                                      NseIconBadge(icon: tool.icon),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(tool.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                            if (count != null)
                                              Text(
                                                count > 0 ? '$count waiting' : 'All clear',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: count > 0 ? AppColors.gold : AppColors.inkSoft,
                                                      fontWeight: count > 0 ? FontWeight.w600 : FontWeight.w400,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    childCount: visibleSections.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                  child: Text(
                    isSuper
                        ? 'Super Admin: you can manage every section below.'
                        : 'You are seeing only the sections assigned to your role. Tap a card to manage it.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminQueueScreen extends ConsumerStatefulWidget {
  const AdminQueueScreen({
    super.key,
    required this.title,
    required this.table,
    required this.statusField,
    required this.statuses,
    required this.roles,
  });

  final String title;
  final String table;
  final String statusField;
  final List<String> statuses;
  final List<String> roles;

  @override
  ConsumerState<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends ConsumerState<AdminQueueScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref
        .read(supabaseProvider)
        .from(widget.table)
        .select()
        .order('created_at', ascending: false)
        .limit(50)
        .then((data) => (data as List).cast<Map<String, dynamic>>());
  }

  Future<void> _advance(Map<String, dynamic> row) async {
    final status = row[widget.statusField] as String? ?? '';
    final next = widget.statuses.indexOf(status) + 1;
    if (next >= widget.statuses.length) return;
    await ref.read(supabaseProvider).from(widget.table).update({
      widget.statusField: widget.statuses[next],
    }).eq('id', row['id']);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AdminGate(
      requiredRoles: widget.roles,
      child: Scaffold(
        body: FutureBuilder(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return Column(children: [
                NseTitleHeader(title: widget.title, subtitle: 'Live queue for staff actions.', onBack: () => context.pop()),
                const Expanded(child: LoadingView()),
              ]);
            }
            final rows = snap.data!;
            if (rows.isEmpty) {
              return Column(children: [
                NseTitleHeader(title: widget.title, subtitle: 'Live queue for staff actions.', onBack: () => context.pop()),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: NseEmptyState(title: 'Queue empty', body: 'No items waiting right now.'),
                  ),
                ),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              children: [
                NseTitleHeader(
                  title: widget.title,
                  subtitle: 'Live queue for staff actions.',
                  onBack: () => context.pop(),
                  padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.md),
                ),
                ...rows.map((r) {
                  final status = r[widget.statusField] as String? ?? '';
                  final next = widget.statuses.indexOf(status) + 1;
                  final label = r['pickup_location'] as String? ??
                      r['reason'] as String? ??
                      r['category'] as String? ??
                      'Item';
                  final detail = (r['description'] as String?)?.trim().isNotEmpty == true
                      ? r['description'] as String
                      : (r['note'] as String?)?.trim().isNotEmpty == true
                          ? r['note'] as String
                          : null;
                  final room = (r['room_number'] as String?)?.trim();
                  final urgency = r['urgency'] as String?;
                  final meta = [
                    if (room != null && room.isNotEmpty) 'Room $room',
                    if (r['location_label'] != null) r['location_label'] as String,
                  ].join(' · ');
                  final isUrgent = urgency == 'urgent';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label.replaceAll('_', ' '),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              if (isUrgent) ...[
                                const NseStatusChip(label: 'Urgent', tone: AppColors.goldSoft, textColor: AppColors.gold),
                                const SizedBox(width: 6),
                              ],
                              NseStatusChip(label: status.replaceAll('_', ' ')),
                            ],
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: 6),
                            Text(detail, style: Theme.of(context).textTheme.bodySmall),
                          ],
                          if (meta.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(meta, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft)),
                          ],
                          if (next < widget.statuses.length) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _advance(r),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                label: Text(widget.statuses[next].replaceAll('_', ' ')),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AdminListScreen extends ConsumerWidget {
  const AdminListScreen({
    super.key,
    required this.title,
    required this.table,
    required this.roles,
    this.labelField,
  });

  final String title;
  final String table;
  final List<String> roles;
  final String? labelField;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    return AdminGate(
      requiredRoles: roles,
      child: Scaffold(
        body: FutureBuilder(
          future: client.from(table).select().order('created_at', ascending: false).limit(100),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Column(children: [
                NseTitleHeader(title: title, subtitle: 'Read-only roster view.', onBack: () => context.pop()),
                const Expanded(child: LoadingView()),
              ]);
            }
            final rows = (snap.data as List).cast<Map<String, dynamic>>();
            if (rows.isEmpty) {
              return Column(children: [
                NseTitleHeader(title: title, subtitle: 'Read-only roster view.', onBack: () => context.pop()),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: NseEmptyState(title: 'No records', body: 'Nothing to show in this list yet.'),
                  ),
                ),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              children: [
                NseTitleHeader(
                  title: title,
                  subtitle: 'Read-only roster view.',
                  onBack: () => context.pop(),
                  padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.md),
                ),
                ...rows.map((r) {
                  final label = r[labelField ?? ''] as String? ??
                      r['title'] as String? ??
                      r['name'] as String? ??
                      r['display_name'] as String? ??
                      r['label'] as String? ??
                      r['id'].toString();
                  final subtitle = r['company'] as String? ?? r['description'] as String? ?? r['bio'] as String?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: Theme.of(context).textTheme.titleSmall),
                          if (subtitle != null && subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }
}

class _AdminStatChip extends StatelessWidget {
  const _AdminStatChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.tone,
    required this.iconColor,
    this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color tone;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104),
      child: NseCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NseIconBadge(icon: icon, tone: tone, iconColor: iconColor, size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
