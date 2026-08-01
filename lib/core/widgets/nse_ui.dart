import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/theme/app_theme.dart';

/// Sanitize text coming from dynamic data sources for safe display.
String sanitizeDisplay(String? s) => (s ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Press-scale + light haptic wrapper for tappable surfaces (native feel).
class NseTapScale extends StatefulWidget {
  const NseTapScale({super.key, required this.child, this.onTap, this.scale = 0.97});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<NseTapScale> createState() => _NseTapScaleState();
}

class _NseTapScaleState extends State<NseTapScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Shared NSE design-system widgets.
class NseCard extends StatelessWidget {
  const NseCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.tint,
    this.borderless = false,
    this.flat = false,
    this.outlined = false,
    this.radius = AppSpacing.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? tint;
  final bool borderless;
  final bool flat;

  /// Opt-in hairline border (rarely needed now that cards float on shadow).
  final bool outlined;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    final fill = tint ?? (flat ? AppColors.muted : AppColors.surface);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: outlined ? AppColors.border : AppColors.border.withValues(alpha: 0.72),
        ),
        boxShadow: flat ? null : AppShadows.card,
      ),
      child: content,
    );

    if (onTap == null) return card;
    return NseTapScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.navy.withValues(alpha: 0.06),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: card,
            ),
        ),
      ),
    );
  }
}

class NseSectionTitle extends StatelessWidget {
  const NseSectionTitle({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (action != null) action!,
        ],
      ),
    );
  }
}

class NseIconBadge extends StatelessWidget {
  const NseIconBadge({
    super.key,
    required this.icon,
    this.tone = AppColors.navySoft,
    this.iconColor = AppColors.navy,
    this.size = 44,
  });

  final IconData icon;
  final Color tone;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: iconColor, size: size * 0.46),
    );
  }
}

class NseQuickAction extends StatelessWidget {
  const NseQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.navy,
    this.accentSoft = AppColors.navySoft,
    this.emphasis = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final Color accentSoft;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      onTap: onTap,
      child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: emphasis ? Border.all(color: accent.withValues(alpha: 0.4), width: 1.2) : null,
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                NseIconBadge(icon: icon, tone: accentSoft, iconColor: accent, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent.withValues(alpha: 0.7), size: 20),
              ],
            ),
          ),
        ),
    );
  }
}

class NseListRow extends StatelessWidget {
  const NseListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.leadingTone,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? leadingTone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                NseIconBadge(
                  icon: icon!,
                  tone: leadingTone ?? AppColors.navySoft,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                      ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class NseStatusChip extends StatelessWidget {
  const NseStatusChip({super.key, required this.label, this.tone = AppColors.navySoft, this.textColor});

  final String label;
  final Color tone;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? AppColors.ink,
              letterSpacing: 0.15,
              fontSize: 11,
            ),
      ),
    );
  }
}

enum NseBrandStyle { wordmark, crest }

class NseBrandMark extends StatelessWidget {
  const NseBrandMark({
    super.key,
    this.height = 36,
    this.light = false,
    this.style = NseBrandStyle.wordmark,
  });

  final double height;
  /// Kept for API compatibility; logo always renders in full brand colors.
  final bool light;
  final NseBrandStyle style;

  String get _asset => style == NseBrandStyle.crest
      ? 'assets/images/nse_crest.png'
      : 'assets/images/nse_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: EventConfig.logoUrl,
      height: height,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) => Text(
        EventConfig.shortName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: light ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

/// Crest inside a white circle — high-contrast, crisp brand lockup for use on
/// dark/navy surfaces (the colour crest renders at/below its source size).
class NseBrandCoin extends StatelessWidget {
  const NseBrandCoin({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/nse_crest.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.engineering_rounded, color: AppColors.navy),
      ),
    );
  }
}

class NseHeroHeader extends StatelessWidget {
  const NseHeroHeader({
    super.key,
    required this.greeting,
    this.subtitle,
    this.trailing,
    this.bottom,
    this.compact = false,
  });

  final String greeting;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(compact ? 24 : 30),
        ),
        boxShadow: AppShadows.elevated,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.heroSheen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(compact ? 24 : 30),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                compact ? AppSpacing.sm : AppSpacing.md,
                AppSpacing.md,
                compact ? AppSpacing.md : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NseBrandCoin(size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      letterSpacing: 0.4,
                                    ),
                              ),
                            Text(
                              greeting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ?trailing,
                    ],
                  ),
                  if (bottom != null) ...[
                    SizedBox(height: compact ? 14 : 18),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable search field — used as a hero "bottom" affordance. Looks like an
/// input but routes to the full search screen (references use this pattern).
class NseSearchBar extends StatelessWidget {
  const NseSearchBar({super.key, required this.onTap, this.hint = 'Search the conference'});

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppShadows.card,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.navy, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
              ),
            ),
            const Icon(Icons.tune_rounded, color: AppColors.navy, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Big, confident screen title for pushed pages (references use large body
/// headings rather than tiny app-bar titles). Pair with a transparent AppBar.
class NseTitleHeader extends StatelessWidget {
  const NseTitleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.md),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// When set, a back chevron is shown to the left of the title.
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Top SafeArea guarantees the header never slides under the status bar.
    // Nested inside an existing SafeArea (e.g. the shell) it adds zero padding.
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _HeaderBackButton(onTap: onBack!),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.card,
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.ink),
      ),
    );
  }
}

/// Compact stadium chip for filters (day, track, tier, suggestions).
class NsePillChip extends StatelessWidget {
  const NsePillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtle = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.navy : (subtle ? AppColors.surface : AppColors.navySoft);
    return NseTapScale(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? AppShadows.card : null,
          border: subtle && !selected ? Border.all(color: AppColors.border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Polished confirm/cancel dialog used for destructive admin actions.
class NseConfirmDialog extends StatelessWidget {
  const NseConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => NseConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: destructive
                        ? FilledButton.styleFrom(backgroundColor: AppColors.destructive)
                        : null,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Consistent bottom sheet shell with drag handle and title.
class NseBottomSheet extends StatelessWidget {
  const NseBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget child,
    bool scrollControlled = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: scrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => NseBottomSheet(title: title, subtitle: subtitle, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        boxShadow: AppShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            MediaQuery.paddingOf(context).bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Rich 2-column service/nav tile: icon badge, title, supporting line.
class NseServiceTile extends StatelessWidget {
  const NseServiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tone = AppColors.navySoft,
    this.iconColor = AppColors.navy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color tone;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NseIconBadge(icon: icon, tone: tone, iconColor: iconColor, size: 46),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calendar-style time block for schedule rows (big start time + end time).
class NseTimeBlock extends StatelessWidget {
  const NseTimeBlock({super.key, required this.start, this.end, this.tone = AppColors.navySoft, this.color = AppColors.navy});

  final String start;
  final String? end;
  final Color tone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              start,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          if (end != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                end!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact square tile for a 2-column home tool grid.
class NseToolTile extends StatelessWidget {
  const NseToolTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.navy,
    this.accentSoft = AppColors.navySoft,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    return NseTapScale(
      onTap: onTap,
      child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NseIconBadge(icon: icon, tone: accentSoft, iconColor: accent, size: 40),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class NseStatsStrip extends StatelessWidget {
  const NseStatsStrip({super.key, required this.stats});

  final List<Map<String, String>> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth < 320 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: crossCount == 2 ? 2.4 : 1.35,
          ),
          itemBuilder: (context, i) {
            final s = stats[i];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    s['value'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['label'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class NsePage extends StatelessWidget {
  const NsePage({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
    this.hero,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final Widget? hero;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (hero != null)
          SliverToBoxAdapter(child: hero!)
        else if (title != null)
          SliverToBoxAdapter(
            child: NseTitleHeader(
              title: title!,
              subtitle: subtitle,
              trailing: actions == null
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions!),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            ),
          ),
        SliverPadding(padding: padding, sliver: SliverToBoxAdapter(child: child)),
      ],
    );
  }
}

class NseEmptyState extends StatelessWidget {
  const NseEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NseIconBadge(icon: icon, tone: AppColors.greenSoft, iconColor: AppColors.green, size: 52),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class NseLoadingBlock extends StatelessWidget {
  const NseLoadingBlock({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: List.generate(lines, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: i == 0 ? 18 : 14,
              width: i == 0 ? double.infinity : (i.isEven ? double.infinity : 220),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NseWifiCard extends StatelessWidget {
  const NseWifiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NseCard(
      tint: AppColors.cream,
      child: Row(
        children: [
          const NseIconBadge(
            icon: Icons.wifi_rounded,
            tone: AppColors.goldSoft,
            iconColor: AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONFERENCE WI-FI', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  EventConfig.wifiSsid,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'monospace'),
                ),
                Text(
                  'Password: ${EventConfig.wifiPassword}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NseGroupedList extends StatelessWidget {
  const NseGroupedList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return NseCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, indent: 68, color: AppColors.border.withValues(alpha: 0.6)),
          ],
        ],
      ),
    );
  }
}

class NseMenuItemTile extends StatelessWidget {
  const NseMenuItemTile({
    super.key,
    required this.name,
    this.description,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.canAdd = true,
    this.itemMax,
    this.isOtherChosen = false,
  });

  final String name;
  final String? description;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool canAdd;
  final int? itemMax;
  final bool isOtherChosen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NseCard(
        flat: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.replaceAll(RegExp(r'\s+'), ' '),
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        description!.replaceAll(RegExp(r'\s+'), ' '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (itemMax != null && itemMax! > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Up to $itemMax per order',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (quantity > 0)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                    ),
                    Text('$quantity', style: Theme.of(context).textTheme.labelLarge),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: canAdd ? onAdd : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: canAdd ? onAdd : null,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(isOtherChosen ? 'Swap in' : 'Add'),
              ),
          ],
        ),
      ),
    );
  }
}

class NseAvatar extends StatelessWidget {
  const NseAvatar({super.key, required this.name, this.radius = 22, this.imageUrl});

  final String? name;
  final double radius;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Handle data URLs (base64 images from demo mode)
      if (imageUrl!.startsWith('data:')) {
        try {
          final base64String = imageUrl!.split(',').last;
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {
          // Fall through to default if parsing fails
        }
      }
      // Handle network URLs
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navySoft,
      child: Text(
        _initials(name),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
          color: AppColors.navy,
        ),
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class NseChatBubble extends StatelessWidget {
  const NseChatBubble({
    super.key,
    required this.text,
    required this.mine,
    this.author,
    this.markdown = false,
  });

  final String text;
  final bool mine;
  final String? author;
  final bool markdown;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          boxShadow: mine ? null : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (author != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  author!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: mine ? Colors.white70 : AppColors.inkSoft,
                      ),
                ),
              ),
            if (markdown)
              MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mine ? Colors.white : AppColors.ink,
                      ),
                ),
              )
            else
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mine ? Colors.white : AppColors.ink,
                      height: 1.4,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class NseChatComposer extends StatelessWidget {
  const NseChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.hint = 'Message',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSend,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
