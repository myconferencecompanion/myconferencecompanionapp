import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/global_search.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/features/chatbot/chatbot_screen.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<SearchHit> _results = [];
  bool _loading = false;
  bool _indexReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
    }
    _controller.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _warmAndSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _warmAndSearch() async {
    final auth = ref.read(authProvider);
    final client = ref.read(supabaseProvider);
    setState(() => _loading = true);
    await GlobalSearch.warmIndex(client, includeAdmin: auth.canAccessAdmin);
    if (!mounted) return;
    setState(() {
      _indexReady = true;
      _loading = false;
    });
    await _runSearch(_controller.text);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () => _runSearch(_controller.text));
  }

  Future<void> _runSearch(String raw) async {
    if (!_indexReady) return;
    final auth = ref.read(authProvider);
    final client = ref.read(supabaseProvider);
    final hits = await GlobalSearch.query(
      raw,
      client: client,
      includeAdmin: auth.canAccessAdmin,
    );
    if (!mounted) return;
    setState(() => _results = hits);
  }

  void _openHit(SearchHit hit) {
    if (hit.faqAnswer != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatbotScreen(
            initialQuestion: hit.title,
            initialAnswer: hit.faqAnswer,
          ),
        ),
      );
      return;
    }
    context.push(hit.route);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final grouped = <String, List<SearchHit>>{};
    for (final hit in _results) {
      grouped.putIfAbsent(hit.group, () => []).add(hit);
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search sessions, food, Wi-Fi, people…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _results = []);
                                },
                                icon: const Icon(Icons.close_rounded, size: 20),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(color: AppColors.gold, minHeight: 2),
            Expanded(
              child: query.isEmpty ? _emptyState(context) : _resultsBody(context, grouped),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: [
        Text('Quick searches', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GlobalSearch.quickQueries
              .map(
                (q) => NsePillChip(
                  label: q,
                  selected: false,
                  subtle: true,
                  onTap: () {
                    _controller.text = q;
                    _controller.selection = TextSelection.collapsed(offset: q.length);
                    _runSearch(q);
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Browse', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        ...const [
          ('Programme', 'Sessions, speakers, agenda', Icons.calendar_month_rounded),
          ('Concierge', 'Food, usher, errands', Icons.room_service_rounded),
          ('Venue & city', 'Maps, hotels, Maiduguri', Icons.explore_rounded),
          ('Help', 'FAQs and Conference Guide', Icons.auto_awesome_rounded),
        ].map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NseCard(
              onTap: () {
                _controller.text = row.$1;
                _runSearch(row.$1);
              },
              child: Row(
                children: [
                  NseIconBadge(icon: row.$3, tone: AppColors.navySoft, iconColor: AppColors.navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.$1, style: Theme.of(context).textTheme.titleSmall),
                        Text(row.$2, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultsBody(BuildContext context, Map<String, List<SearchHit>> grouped) {
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: NseEmptyState(
            title: 'No matches',
            body: 'Try Wi-Fi, food, schedule, speakers, or hotels.',
            icon: Icons.search_off_rounded,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8, left: 2),
            child: Row(
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(width: 8),
                Text('${entry.value.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft)),
              ],
            ),
          ),
          ...entry.value.map((hit) => _resultTile(context, hit)),
        ],
      ],
    );
  }

  Widget _resultTile(BuildContext context, SearchHit hit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NseCard(
        onTap: () => _openHit(hit),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            NseIconBadge(icon: hit.icon, tone: hit.iconTone, iconColor: hit.iconColor, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hit.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (hit.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        hit.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.inkSoft.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

/// Tappable search bar — opens the global search screen.
class NseSearchTrigger extends StatelessWidget {
  const NseSearchTrigger({super.key, this.hint = 'Search anything…'});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/search'),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.inkSoft.withValues(alpha: 0.85)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  ),
                ),
                Icon(Icons.travel_explore_rounded, size: 18, color: AppColors.inkSoft.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
