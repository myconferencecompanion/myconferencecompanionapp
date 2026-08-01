import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/features/search/global_search_screen.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final items = [
      (Icons.bookmark_rounded, 'My agenda', '/agenda', AppColors.goldSoft, AppColors.gold),
      (Icons.groups_rounded, 'Networking', '/network', AppColors.greenSoft, AppColors.green),
      (Icons.campaign_rounded, 'Announcements', '/announcements', AppColors.goldSoft, AppColors.gold),
      (Icons.health_and_safety_rounded, 'Emergency', '/emergency', AppColors.destructiveSoft, AppColors.destructive),
      (Icons.person_rounded, 'Profile', '/profile', AppColors.navySoft, AppColors.navy),
      (Icons.calendar_month_rounded, 'Schedule', '/schedule', AppColors.navySoft, AppColors.navy),
      (Icons.mic_rounded, 'Speakers', '/speakers', AppColors.greenSoft, AppColors.green),
      (Icons.hotel_rounded, 'Hotels', '/accommodation', AppColors.goldSoft, AppColors.gold),
      (Icons.explore_rounded, 'Maiduguri guide', '/maidguide', AppColors.greenSoft, AppColors.green),
      (Icons.auto_awesome_rounded, 'Conference Guide', '/chatbot', AppColors.navySoft, AppColors.navy),
      (Icons.info_rounded, 'About NSE', '/about', AppColors.navySoft, AppColors.navy),
    ];

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: NseTitleHeader(
              title: 'More',
              subtitle: 'Settings, shortcuts, and conference utilities',
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const NseSearchTrigger(),
              const SizedBox(height: AppSpacing.md),
              const NseWifiCard(),
              const SizedBox(height: AppSpacing.md),
              NseGroupedList(
                children: items
                    .map(
                      (item) => NseListRow(
                        icon: item.$1,
                        title: item.$2,
                        leadingTone: item.$4,
                        onTap: () => context.push(item.$3),
                      ),
                    )
                    .toList(),
              ),
              if (auth.canAccessAdmin) ...[
                const SizedBox(height: AppSpacing.md),
                NseCard(
                  onTap: () => context.push('/admin'),
                  child: const NseListRow(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin dashboard',
                    subtitle: 'Program, catering, front desk, and delegates',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go('/auth');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  '${EventConfig.name}\n${EventConfig.dates}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
