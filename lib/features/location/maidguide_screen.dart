import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class MaidguideScreen extends StatelessWidget {
  const MaidguideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final links = <(IconData, String, String, String, Color, Color)>[
      (Icons.map_rounded, 'Venue map', 'Indoor ICC layout & outdoor view', '/map', AppColors.navySoft, AppColors.navy),
      (Icons.directions_rounded, 'Directions', 'Get to the conference centre', '/directions', AppColors.greenSoft, AppColors.green),
      (Icons.hotel_rounded, 'Hotels', 'Delegate accommodation', '/accommodation', AppColors.goldSoft, AppColors.gold),
      (Icons.place_rounded, 'Nearby', 'Airport, security, hospitals & more', '/nearby', AppColors.navySoft, AppColors.navy),
      (Icons.info_rounded, 'About NSE', 'Conference identity & context', '/about', AppColors.greenSoft, AppColors.green),
    ];

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
        children: [
          const NseTitleHeader(
            title: 'Maiduguri guide',
            subtitle: 'Maps, hotels, directions & on-the-ground essentials.',
            padding: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: links
                .map(
                  (l) => NseServiceTile(
                    icon: l.$1,
                    title: l.$2,
                    subtitle: l.$3,
                    tone: l.$5,
                    iconColor: l.$6,
                    onTap: () => context.push(l.$4),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
