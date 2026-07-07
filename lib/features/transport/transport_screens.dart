import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/data/reference_data.dart';
import 'package:nse_mobile/data/transport_data.dart';
import 'package:nse_mobile/features/admin/admin_screens.dart';
import 'package:nse_mobile/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MyTransportScreen extends ConsumerWidget {
  const MyTransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final client = ref.watch(supabaseProvider);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: _load(client, auth.userId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'My transport'),
              Expanded(child: LoadingView()),
            ]);
          }
          final data = snap.data!;
          final bus = data.bus;
          final policy = data.policy;
          final hotel = data.hotel;
          final runs = data.runs;
          final assignment = data.assignment;

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              NseTitleHeader(
                title: 'My transport',
                subtitle: _policyExplain(policy),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
              ),
              if (bus != null) ...[
                NseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NseIconBadge(
                            icon: Icons.directions_bus_rounded,
                            tone: AppColors.navySoft,
                            iconColor: AppColors.navy,
                            size: 52,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bus.name, style: Theme.of(context).textTheme.titleLarge),
                                Text(bus.routeLabel, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _row(context, 'Home hotel', hotel?.name ?? bus.hotelId),
                      _row(context, 'Pickup', bus.pickupPoint),
                      _row(context, 'Marshal', bus.marshalName),
                      if (assignment != null)
                        _row(context, 'Seat manifest', 'Assigned · capacity ${bus.capacity}'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:${bus.marshalPhone}')),
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text('Call marshal'),
                      ),
                    ),
                  ],
                ),
              ] else
                const NseCard(
                  child: Text('No bus assigned yet. Contact logistics at registration.'),
                ),
              const SizedBox(height: AppSpacing.lg),
              const NseSectionTitle(title: 'Today\'s shuttle times'),
              ...runs.take(5).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NseCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.label, style: Theme.of(context).textTheme.titleSmall),
                                  Text(
                                    r.direction == 'to_venue' ? 'Hotel → ICC' : 'ICC → Hotel',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            NseStatusChip(
                              label: r.status == 'departed' ? 'Departed' : 'Scheduled',
                              tone: r.isLocked ? AppColors.greenSoft : AppColors.navySoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              if (auth.canAccessAdmin && auth.hasAnyAdminRole(['logistics', 'admin', 'super_admin'])) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => context.push('/transport/admin'),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Transport control (staff)'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.labelSmall)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _policyExplain(BoardingPolicy p) => switch (p) {
        BoardingPolicy.fixedAssignment =>
          'You have one home bus for the entire conference. Board only your assigned bus so marshals can track headcount.',
        BoardingPolicy.openBoarding =>
          'Board any bus going to your hotel. Marshals take a one-time headcount before each departure.',
        BoardingPolicy.hybrid =>
          'You have a home bus, but route buses may accept you when needed. Each run is counted once and locked after departure.',
      };

  Future<_TransportView> _load(dynamic client, String? userId) async {
    final catalog = await TransportCatalog.load();
    final settingsRows = await client.from('transport_settings').select().limit(1);
    final policyId = settingsRows.isNotEmpty
        ? settingsRows.first['boarding_policy'] as String? ?? 'hybrid'
        : boardingPolicyId(catalog.defaultPolicy);
    final policy = boardingPolicyFromId(policyId);

    Map<String, dynamic>? assignment;
    if (userId != null) {
      final rows = await client.from('transport_assignments').select().eq('user_id', userId).limit(1);
      if (rows.isNotEmpty) assignment = Map<String, dynamic>.from(rows.first as Map);
    }

    TransportBus? bus;
    ReferenceHotel? hotel;
    if (assignment != null) {
      final busId = assignment['bus_id'] as String?;
      bus = catalog.buses.where((b) => b.id == busId).firstOrNull;
      if (bus != null) hotel = await ReferenceData.hotelById(bus.hotelId);
    }

    final runs = <TransportRun>[];
    if (bus != null) {
      final runRows = await client
          .from('transport_runs')
          .select()
          .eq('bus_id', bus.id)
          .order('scheduled_at');
      for (final r in runRows) {
        runs.add(TransportRun.fromJson(Map<String, dynamic>.from(r as Map)));
      }
    }

    return _TransportView(policy: policy, bus: bus, hotel: hotel, assignment: assignment, runs: runs);
  }
}

class _TransportView {
  _TransportView({
    required this.policy,
    required this.bus,
    required this.hotel,
    required this.assignment,
    required this.runs,
  });

  final BoardingPolicy policy;
  final TransportBus? bus;
  final ReferenceHotel? hotel;
  final Map<String, dynamic>? assignment;
  final List<TransportRun> runs;
}

class TransportAdminScreen extends ConsumerStatefulWidget {
  const TransportAdminScreen({super.key});

  @override
  ConsumerState<TransportAdminScreen> createState() => _TransportAdminScreenState();
}

class _TransportAdminScreenState extends ConsumerState<TransportAdminScreen> {
  BoardingPolicy? _policy;
  String? _selectedBusId;
  String? _selectedRunId;
  int _refresh = 0;

  @override
  Widget build(BuildContext context) {
    return AdminGate(
      requiredRoles: const ['logistics', 'admin', 'super_admin'],
      child: Scaffold(
        body: FutureBuilder(
          future: _loadAdmin(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Column(children: [
                NseTitleHeader(title: 'Transport control', subtitle: 'Bus roster, runs, and boarding.'),
                Expanded(child: LoadingView()),
              ]);
            }
            final data = snap.data!;
            final catalog = data.catalog;
            final policy = _policy ?? data.policy;
            final buses = catalog.buses;
            final busId = _selectedBusId ?? buses.first.id;
            final bus = buses.firstWhere((b) => b.id == busId);
            final runs = data.runsByBus[busId] ?? [];
            final runId = _selectedRunId ?? (runs.isNotEmpty ? runs.first.id : null);
            final run = runId != null ? runs.where((r) => r.id == runId).firstOrNull : null;
            final roster = data.roster;
            final boarded = data.boardedIds;
            final busRoster = roster.where((p) {
              if (policy == BoardingPolicy.openBoarding) return true;
              final assignBus = p['bus_id'] as String?;
              if (policy == BoardingPolicy.hybrid) {
                return assignBus == busId || assignBus == null;
              }
              return assignBus == busId;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              children: [
                NseTitleHeader(
                  title: 'Transport control',
                  subtitle: 'Bus roster, runs, and boarding.',
                  onBack: () => context.pop(),
                  padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.md),
                ),
                NseCard(
                  tint: AppColors.cream,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Boarding policy', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      RadioGroup<BoardingPolicy>(
                        groupValue: policy,
                        onChanged: (v) {
                          if (v == null || run?.isLocked == true) return;
                          setState(() => _policy = v);
                          ref.read(supabaseProvider).from('transport_settings').upsert({
                            'id': 'default',
                            'boarding_policy': boardingPolicyId(v),
                          });
                        },
                        child: Column(
                          children: BoardingPolicy.values.map((p) {
                            return RadioListTile<BoardingPolicy>(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(boardingPolicyLabel(p)),
                              subtitle: Text(_policyHint(p), style: Theme.of(context).textTheme.bodySmall),
                              value: p,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const NseSectionTitle(title: 'Buses'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: buses
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(b.name),
                              selected: b.id == busId,
                              onSelected: (_) => setState(() {
                                _selectedBusId = b.id;
                                _selectedRunId = null;
                              }),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                NseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${bus.name} · ${bus.routeLabel}', style: Theme.of(context).textTheme.titleSmall),
                      Text('Capacity ${bus.capacity} · ${bus.pickupPoint}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (runs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const NseSectionTitle(title: 'Active run (one-time headcount)'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('run-dd-$busId'),
                    initialValue: runId,
                    decoration: const InputDecoration(labelText: 'Shuttle run'),
                    items: runs
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text('${r.label} · ${r.status}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRunId = v),
                  ),
                  if (run != null) ...[
                    const SizedBox(height: 8),
                    NseCard(
                      tint: run.isLocked ? AppColors.greenSoft : AppColors.goldSoft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${boarded.length} / ${bus.capacity} boarded'
                              '${run.isLocked ? ' · Locked' : ''}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (!run.isLocked)
                            FilledButton(
                              onPressed: boarded.isEmpty
                                  ? null
                                  : () async {
                                      await ref.read(supabaseProvider).from('transport_runs').update({
                                        'status': 'departed',
                                        'locked_at': DateTime.now().toUtc().toIso8601String(),
                                      }).eq('id', run.id);
                                      setState(() => _refresh++);
                                    },
                              child: const Text('Depart & lock'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Headcount is taken once per run. After departure the manifest cannot be changed.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...busRoster.map((p) {
                      final id = p['user_id'] as String;
                      final on = boarded.contains(id);
                      final name = p['display_name'] as String? ?? 'Delegate';
                      return NseCard(
                        onTap: run.isLocked
                            ? null
                            : () async {
                                final client = ref.read(supabaseProvider);
                                if (on) {
                                  await client.from('transport_boardings').delete().match({
                                    'run_id': run.id,
                                    'user_id': id,
                                  });
                                } else {
                                  if (boarded.length >= bus.capacity) return;
                                  await client.from('transport_boardings').upsert({
                                    'run_id': run.id,
                                    'user_id': id,
                                    'bus_id': bus.id,
                                  });
                                }
                                setState(() => _refresh++);
                              },
                        child: Row(
                          children: [
                            Icon(
                              on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: on ? AppColors.green : AppColors.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(name)),
                            if (p['bus_id'] != null && p['bus_id'] != busId)
                              NseStatusChip(label: 'Route', tone: AppColors.goldSoft),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _policyHint(BoardingPolicy p) => switch (p) {
        BoardingPolicy.fixedAssignment => 'Strict manifest — only assigned delegates per bus.',
        BoardingPolicy.openBoarding => 'Any delegate may board a route bus; count at departure.',
        BoardingPolicy.hybrid => 'Home bus plus overflow route boarding when needed.',
      };

  Future<_AdminData> _loadAdmin() async {
    // ignore: unused_local_variable
    final _ = _refresh;
    final client = ref.read(supabaseProvider);
    final catalog = await TransportCatalog.load();
    final settingsRows = await client.from('transport_settings').select().limit(1);
    final policy = boardingPolicyFromId(
      settingsRows.isNotEmpty
          ? settingsRows.first['boarding_policy'] as String? ?? 'hybrid'
          : boardingPolicyId(catalog.defaultPolicy),
    );

    final profiles = await client.from('profiles').select('id, display_name');
    final assignments = await client.from('transport_assignments').select();
    final assignByUser = <String, String>{};
    for (final a in assignments) {
      final m = Map<String, dynamic>.from(a as Map);
      assignByUser[m['user_id'] as String] = m['bus_id'] as String;
    }
    final roster = profiles
        .map((p) {
          final m = Map<String, dynamic>.from(p as Map);
          return {
            'user_id': m['id'],
            'display_name': m['display_name'],
            'bus_id': assignByUser[m['id'] as String],
          };
        })
        .toList()
        .cast<Map<String, dynamic>>();

    final runRows = await client.from('transport_runs').select().order('scheduled_at');
    final runsByBus = <String, List<TransportRun>>{};
    for (final r in runRows) {
      final run = TransportRun.fromJson(Map<String, dynamic>.from(r as Map));
      runsByBus.putIfAbsent(run.busId, () => []).add(run);
    }

    final boardingRows = await client.from('transport_boardings').select();
    final activeRunId = _selectedRunId ?? runsByBus.values.expand((e) => e).firstOrNull?.id;
    final boardedIds = activeRunId == null
        ? <String>{}
        : boardingRows
            .where((b) => b['run_id'] == activeRunId)
            .map((b) => b['user_id'] as String)
            .toSet();

    return _AdminData(
      catalog: catalog,
      policy: policy,
      roster: roster,
      runsByBus: runsByBus,
      boardedIds: boardedIds,
    );
  }
}

class _AdminData {
  _AdminData({
    required this.catalog,
    required this.policy,
    required this.roster,
    required this.runsByBus,
    required this.boardedIds,
  });

  final TransportCatalog catalog;
  final BoardingPolicy policy;
  final List<Map<String, dynamic>> roster;
  final Map<String, List<TransportRun>> runsByBus;
  final Set<String> boardedIds;
}
