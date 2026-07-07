import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/db_query.dart';
import 'package:nse_mobile/core/refresh_signals.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    final client = ref.read(supabaseProvider);
    setState(() {
      _future = dbWait([
        client.from('usher_requests').select().eq('user_id', userId).inFilter('status', ['pending', 'acknowledged']),
        client.from('food_orders').select().eq('user_id', userId).inFilter('status', ['pending', 'preparing', 'ready']),
        client.from('errand_requests').select().eq('user_id', userId).inFilter('status', ['requested', 'accepted', 'in_progress']),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activityRefreshProvider, (prev, next) => _reload());

    final userId = ref.watch(authProvider).userId;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NseTitleHeader(
            title: 'Activity',
            subtitle: 'Live status for your conference requests',
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          ),
          Expanded(
            child: userId == null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 24),
                    children: const [
                      NseEmptyState(
                        title: 'Sign in required',
                        body: 'Your live usher, food, and errand requests appear here.',
                        icon: Icons.lock_outline_rounded,
                      ),
                    ],
                  )
                : FutureBuilder(
                    future: _future,
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                          child: NseLoadingBlock(lines: 5),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async => _reload(),
                        color: AppColors.navy,
                        child: _ActivityBody(data: snap.data!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({required this.data});
  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    final usher = data[0] as List;
    final food = data[1] as List;
    final errands = data[2] as List;
    final total = usher.length + food.length + errands.length;

    if (total == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 24),
        children: [
          NseEmptyState(
            title: 'All clear',
            body: 'No active requests right now. Concierge can help with usher calls, meals, and errands.',
            icon: Icons.check_circle_outline_rounded,
            action: FilledButton(
              onPressed: () => context.push('/concierge'),
              child: const Text('Open Concierge'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 24),
      children: [
        if (usher.isNotEmpty) ...[
          const NseSectionTitle(title: 'Usher'),
          ...usher.map((r) => _ActivityCard(
                title: r['reason'] as String,
                subtitle: r['location_label'] as String? ?? '',
                status: r['status'] as String,
              )),
        ],
        if (food.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const NseSectionTitle(title: 'Food orders'),
          ...food.map((r) => _ActivityCard(
                title: r['pickup_location'] as String? ?? 'Food order',
                subtitle: 'Conference catering',
                status: r['status'] as String,
              )),
        ],
        if (errands.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const NseSectionTitle(title: 'Errands'),
          ...errands.map((r) => _ActivityCard(
                title: r['category'] as String,
                subtitle: r['description'] as String? ?? '',
                status: r['status'] as String,
              )),
        ],
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.title, required this.subtitle, required this.status});

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NseCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            NseStatusChip(label: status.replaceAll('_', ' ')),
          ],
        ),
      ),
    );
  }
}
