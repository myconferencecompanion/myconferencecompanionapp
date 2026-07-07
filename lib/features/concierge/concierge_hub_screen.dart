import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class ConciergeHubScreen extends StatelessWidget {
  const ConciergeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, String, Color, Color)>[
      (Icons.support_agent_rounded, 'Call an usher', 'Assistance, accessibility & lost items', '/concierge/usher', AppColors.navySoft, AppColors.navy),
      (Icons.directions_bus_rounded, 'My transport', 'Your bus, marshal & shuttle times', '/transport', AppColors.greenSoft, AppColors.green),
      (Icons.restaurant_menu_rounded, 'Food menu', 'Complimentary delegate meals', '/concierge/food', AppColors.goldSoft, AppColors.gold),
      (Icons.local_laundry_service_rounded, 'Errands', 'Laundry, pharmacy & more', '/concierge/errands', AppColors.greenSoft, AppColors.green),
      (Icons.receipt_long_rounded, 'My orders', 'Track food & errand requests', '/concierge/orders', AppColors.navySoft, AppColors.navy),
    ];

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: NseTitleHeader(
              title: 'Concierge',
              subtitle: 'On-site support, meals, and errands from the conference team.',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 40),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.98,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final it = items[i];
                  return NseServiceTile(
                    icon: it.$1,
                    title: it.$2,
                    subtitle: it.$3,
                    tone: it.$5,
                    iconColor: it.$6,
                    onTap: () => context.push(it.$4),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
