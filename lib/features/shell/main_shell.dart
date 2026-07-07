import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/refresh_signals.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.notifications_none_rounded, Icons.notifications_rounded, 'Activity'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'More'),
  ];

  void _onTap(WidgetRef ref, int index) {
    HapticFeedback.selectionClick();
    if (index == 1) bumpActivity(ref);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      // go_router's indexed-stack shell uses IndexedStack with the default
      // StackFit.loose, so it only fills the screen when handed *tight*
      // constraints. SizedBox.expand guarantees that and prevents the shell
      // from collapsing to a blank (white) body.
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(child: navigationShell),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppShadows.nav,
        ),
        child: SafeArea(
          top: false,
          // Height MUST be pinned as the outermost box. The Scaffold measures
          // the bottom bar with a loose (up-to-full-screen) height constraint,
          // so any expanding widget (Center/Align) here would stretch the bar
          // to fill the screen and push page content to zero height.
          child: SizedBox(
            height: 64,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(
                          child: _NavItem(
                            icon: _items[i].$1,
                            activeIcon: _items[i].$2,
                            label: _items[i].$3,
                            selected: navigationShell.currentIndex == i,
                            onTap: () => _onTap(ref, i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.navySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 23,
              color: selected ? AppColors.navy : AppColors.inkSoft,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.navy,
                              fontSize: 13.5,
                            ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
