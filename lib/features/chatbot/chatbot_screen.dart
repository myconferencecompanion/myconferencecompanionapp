import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/features/chatbot/conference_guide_service.dart';
import 'package:nse_mobile/features/chatbot/faq_screen.dart';
import 'package:nse_mobile/features/chatbot/guide_nlp.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({
    super.key,
    this.initialQuestion,
    this.initialAnswer,
  });

  final String? initialQuestion;
  final String? initialAnswer;

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({bool user, String text, String? intent})>[];
  bool _busy = false;
  String? _lastTopic;

  static const _suggestions = [
    "What's next?",
    'Wi-Fi and food?',
    'Who is Engr. Wanori?',
    'Sessions in Grand Hall?',
    'Hotels near ICC?',
    'Latest announcement?',
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(q.trim(), widget.initialAnswer);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ConferenceGuideService get _guide =>
      ConferenceGuideService(ref.read(supabaseProvider));

  Future<void> _send([String? text, String? cannedAnswer]) async {
    final msg = (text ?? _input.text).trim();
    if (msg.isEmpty || _busy) return;

    setState(() {
      _messages.add((user: true, text: msg, intent: null));
      _busy = true;
      _input.clear();
    });

    final history = _messages
        .map((m) => GuideTurn(user: m.user, text: m.text, intent: m.intent))
        .toList();

    final reply = cannedAnswer ??
        await _guide.answer(
          msg,
          userName: ref.read(authProvider).displayName,
          lastTopic: _lastTopic,
          history: history,
        );

    if (!mounted) return;
    final topic = cannedAnswer == null ? _inferTopic(msg) : _lastTopic;
    setState(() {
      _messages.add((user: false, text: reply, intent: topic));
      _busy = false;
      _lastTopic = topic;
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  String? _inferTopic(String q) {
    final lower = GuideNlp.normalize(q);
    if (lower.contains('schedule') || lower.contains('next') || lower.contains('session')) {
      return 'schedule';
    }
    if (lower.contains('speaker') || lower.contains('who is') || lower.contains('chairman')) {
      return 'speakers';
    }
    if (lower.contains('hotel')) return 'hotels';
    if (lower.contains('wifi')) return 'wifi';
    if (lower.contains('food') || lower.contains('menu')) return 'food';
    if (lower.contains('emergency')) return 'emergency';
    if (lower.contains('venue') || lower.contains('icc')) return 'venue';
    if (lower.contains('announcement') || lower.contains('news')) return 'announcements';
    if (lower.contains('maiduguri') || lower.contains('shuttle')) return 'maiduguri';
    if (lower.contains('concierge') || lower.contains('badge')) return 'concierge';
    return _lastTopic;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            const NseIconBadge(
              icon: Icons.auto_awesome_rounded,
              tone: AppColors.goldSoft,
              iconColor: AppColors.gold,
              size: 38,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Conference Guide',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('Live answers · 40 FAQs',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (ctx) => FaqScreen(
                  onAsk: (q, a) => _send(q, a),
                ),
              ),
            ),
            icon: const Icon(Icons.quiz_outlined, size: 18),
            label: const Text('FAQs'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: NseCard(
                tint: AppColors.cream,
                child: Text(
                  'Smart guide: live schedule, 40 FAQs, follow-up questions, and multi-topic queries (e.g. *Wi-Fi and food?*).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          if (_messages.isEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: _suggestions
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Center(
                          child: NsePillChip(
                            label: s,
                            selected: false,
                            subtle: true,
                            onTap: () => _send(s),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return NseChatBubble(text: m.text, mine: m.user, markdown: !m.user);
              },
            ),
          ),
          if (_busy) const LinearProgressIndicator(color: AppColors.gold, minHeight: 2),
          NseChatComposer(
            controller: _input,
            onSend: () => _send(),
            hint: 'Ask about the conference…',
          ),
        ],
      ),
    );
  }
}
