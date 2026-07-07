import 'package:flutter/material.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/theme/app_theme.dart';

/// @deprecated Use [NsePage], [NseSectionTitle], [NseEmptyState] from nse_ui.dart.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return NseSectionTitle(title: title, subtitle: subtitle);
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: NseLoadingBlock(lines: 4),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: NseEmptyState(
          title: 'Something went wrong',
          body: message,
          icon: Icons.error_outline_rounded,
          action: onRetry == null ? null : FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.title, required this.body, this.icon});

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return NseEmptyState(title: title, body: body, icon: icon ?? Icons.inbox_outlined);
  }
}
