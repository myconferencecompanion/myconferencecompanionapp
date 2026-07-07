import 'package:flutter/material.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/data/faq_data.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, this.onAsk});

  final void Function(String question, String answer)? onAsk;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();
  Map<String, List<FaqItem>> _grouped = {};
  List<FaqItem> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final grouped = await FaqData.byCategory();
    if (!mounted) return;
    setState(() {
      _grouped = grouped;
      _filtered = grouped.values.expand((e) => e).toList();
      _loading = false;
    });
  }

  Future<void> _filter() async {
    final q = _search.text.trim();
    if (q.isEmpty) {
      setState(() => _filtered = _grouped.values.expand((e) => e).toList());
      return;
    }
    final hits = await FaqData.search(q, limit: 40);
    if (mounted) setState(() => _filtered = hits);
  }

  void _openFaq(FaqItem faq) {
    if (widget.onAsk != null) {
      widget.onAsk!(faq.question, faq.answer);
      Navigator.pop(context);
      return;
    }
    NseBottomSheet.show<void>(
      context,
      title: faq.question,
      subtitle: faq.category,
      child: NseChatBubble(text: faq.answer, mine: false, markdown: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: _loading
          ? const Column(children: [
              NseTitleHeader(title: 'FAQs', subtitle: '40 answers from the conference team.'),
              Expanded(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: NseLoadingBlock(lines: 6))),
            ])
          : Column(
              children: [
                const NseTitleHeader(
                  title: 'FAQs',
                  subtitle: '40 answers from the conference team.',
                  padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search FAQs…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: _search.text.trim().isNotEmpty ? _faqList(_filtered) : _categoryList(),
                ),
              ],
            ),
    );
  }

  Widget _categoryList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      children: _grouped.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: NseCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                title: Text(e.key, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('${e.value.length} questions', style: Theme.of(context).textTheme.bodySmall),
                children: e.value.map((f) => _faqTile(f)).toList(),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _faqList(List<FaqItem> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: NseEmptyState(
          title: 'No matching FAQs',
          body: 'Try a different keyword, or ask the Conference Guide directly.',
          icon: Icons.help_outline_rounded,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) => NseCard(
        padding: EdgeInsets.zero,
        child: _faqTile(items[i]),
      ),
    );
  }

  Widget _faqTile(FaqItem faq) {
    return NseListRow(
      title: faq.question,
      subtitle: faq.category,
      icon: Icons.help_outline_rounded,
      onTap: () => _openFaq(faq),
    );
  }
}
