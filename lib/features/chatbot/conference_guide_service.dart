import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/format.dart';
import 'package:nse_mobile/data/faq_data.dart';
import 'package:nse_mobile/data/reference_data.dart';
import 'package:nse_mobile/features/chatbot/guide_nlp.dart';

/// Conference Guide brain — answers from live app data + reference bundles.
class ConferenceGuideService {
  ConferenceGuideService(this._client);

  final dynamic _client;

  Future<String> answer(
    String question, {
    String? userName,
    String? lastTopic,
    List<GuideTurn> history = const [],
  }) async {
    final raw = question.trim();
    if (raw.isEmpty) return _help(userName);

    final social = GuideNlp.socialReply(raw, userName);
    if (social != null) return social;

    final expanded = GuideNlp.expandQuery(raw, history, lastTopic);

    if (GuideNlp.isCompound(expanded)) {
      final parts = GuideNlp.splitCompound(expanded);
      final answers = <String>[];
      for (final part in parts) {
        final a = await _answerSingle(part, userName: userName, lastTopic: lastTopic);
        answers.add(a);
      }
      return answers.where((a) => a.isNotEmpty).join('\n\n');
    }

    return _answerSingle(expanded, userName: userName, lastTopic: lastTopic);
  }

  Future<String> _answerSingle(
    String question, {
    String? userName,
    String? lastTopic,
  }) async {
    final q = GuideNlp.normalize(question);
    if (q.isEmpty) return _help(userName);

    if (_matches(q, ['faq', 'faqs', 'frequently asked', 'common questions'])) {
      return _faqIndex();
    }

    final ctx = await _loadContext();

    if (_matches(q, ['how many session', 'number of session', 'count session'])) {
      return 'There are **${ctx.sessions.length} sessions** across the conference. Open **Schedule** to browse by day and track.';
    }
    if (_matches(q, ['how many speaker', 'number of speaker'])) {
      return '**${ctx.speakers.length} speakers** are listed — including keynotes. Open **Speakers** or ask *"Who is the chairman?"*';
    }

    final scores = <String, double>{};

    void bump(String intent, double amount) {
      scores[intent] = (scores[intent] ?? 0) + amount;
    }

    for (final e in _intents.entries) {
      final s = _score(q, e.value);
      if (s > 0) bump(e.key, s);
    }

    if (lastTopic != null && question.length < 48) {
      bump(lastTopic, 2);
    }

    _boostFromEntities(q, ctx, bump);

    final (faqItem, faqScore) = await FaqData.bestMatch(question);
    if (faqItem != null && faqScore >= 3) {
      bump('__faq__', faqScore);
    }

    final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (ranked.isNotEmpty && ranked.first.key == '__faq__' && faqItem != null) {
      final topIntent = ranked.length > 1 ? ranked[1] : null;
      if (topIntent == null || ranked.first.value >= topIntent.value + 1.5) {
        return _enrich(faqItem.answer, ctx, 'faq');
      }
    }

    final intents = ranked.where((e) => e.key != '__faq__' && e.value >= 1.5).toList();
    if (intents.length >= 2 && intents[1].value >= intents[0].value * 0.7) {
      return intents
          .take(2)
          .map((e) => _dispatch(e.key, q, ctx, userName))
          .join('\n\n');
    }

    if (intents.isNotEmpty) {
      return _enrich(_dispatch(intents.first.key, q, ctx, userName), ctx, intents.first.key);
    }

    final speaker = _matchSpeaker(q, ctx.speakers);
    if (speaker != null) return _speakerAnswer(speaker, ctx);

    final session = _matchSession(q, ctx.sessions);
    if (session != null) return _sessionAnswer(session);

    if (faqItem != null && faqScore >= 2.5) return faqItem.answer;

    final related = await FaqData.search(question, limit: 3);
    return _smartFallback(q, userName, ranked.take(3).map((e) => e.key).toList(), related);
  }

  String _faqIndex() {
    return '**40 conference FAQs** cover registration, venue, schedule, hotels, Wi-Fi, food, networking, emergency, and Maiduguri.\n\nTap **Browse FAQs** in the app bar or ask any question in your own words.';
  }

  Future<_GuideContext> _loadContext() async {
    final results = await Future.wait<dynamic>([
      ReferenceData.conferenceInfo(),
      ReferenceData.maiduguriPois(),
      ReferenceData.hotels(),
      _client.from('sessions').select().order('starts_at') as Future<dynamic>,
      _client.from('speakers').select().order('name') as Future<dynamic>,
      _client.from('session_speakers').select() as Future<dynamic>,
      _client.from('announcements').select().order('created_at', ascending: false).limit(3) as Future<dynamic>,
      _client.from('emergency_contacts').select().order('sort_order') as Future<dynamic>,
      _client.from('menu_items').select().eq('is_available', true).order('sort_order') as Future<dynamic>,
    ]);

    return _GuideContext(
      info: results[0] as ConferenceInfo,
      pois: results[1] as Map<String, dynamic>,
      hotels: results[2] as List<ReferenceHotel>,
      sessions: (results[3] as List).cast<Map<String, dynamic>>(),
      speakers: (results[4] as List).cast<Map<String, dynamic>>(),
      sessionSpeakers: (results[5] as List).cast<Map<String, dynamic>>(),
      announcements: (results[6] as List).cast<Map<String, dynamic>>(),
      emergency: (results[7] as List).cast<Map<String, dynamic>>(),
      menu: (results[8] as List).cast<Map<String, dynamic>>(),
    );
  }

  String _dispatch(String intent, String q, _GuideContext ctx, String? userName) {
    switch (intent) {
      case 'greeting':
        return _greeting(userName, ctx);
      case 'schedule':
        return _scheduleAnswer(q, ctx);
      case 'speakers':
        return _speakersAnswer(q, ctx);
      case 'dates':
        return '**${ctx.info.conferenceTitle}** runs **${ctx.info.dates}** at ${ctx.info.venue}. Open **Schedule** for the full programme.';
      case 'venue':
        return _venueAnswer(ctx);
      case 'hotels':
        return _hotelsAnswer(ctx);
      case 'wifi':
        return '**Conference Wi-Fi**\n- Network: `${EventConfig.wifiSsid}`\n- Password: `${EventConfig.wifiPassword}`\n\nAlso on **More** → Conference Wi-Fi.';
      case 'emergency':
        return _emergencyAnswer(ctx);
      case 'theme':
        return '**Theme:** ${ctx.info.theme}\n\n**Chairman:** ${ctx.info.chairman}\n\nMore on **About NSE** in the app.';
      case 'food':
        return _foodAnswer(ctx);
      case 'concierge':
        return 'Need on-site help? Open **Concierge** for ushers, badge support, or directions.\n\nRegistration: **Main Lobby** from 7:00 AM daily.';
      case 'networking':
        return 'Meet delegates in **Networking** — browse profiles, direct messages, and room chats.';
      case 'announcements':
        return _announcementsAnswer(ctx);
      case 'entertainment':
        return '**${ctx.info.entertainment['title']}** — ${ctx.info.entertainment['focus']}\n\nChair: ${ctx.info.entertainment['chair']}. See **Schedule** for Cultural Night.';
      case 'spouses':
        return '**${ctx.info.spouses['title']}** at ${ctx.info.spouses['venue']}.\n\n${ctx.info.spouses['focus']}\n\nUpdates in **Announcements**.';
      case 'maiduguri':
        return _maiduguriAnswer(ctx);
      case 'map':
        return 'Open **Venue map** for ICC floor plans. For GPS routes use **Maiduguri guide** → Directions.';
      case 'agenda':
        return 'Save sessions via **My agenda** on any session page. Ask *"what\'s next?"* for upcoming sessions.';
      default:
        return _help(userName);
    }
  }

  String _greeting(String? userName, _GuideContext ctx) {
    final name = userName != null ? greetingFirstName(userName) : 'Delegate';
    final hour = DateTime.now().hour;
    final timeGreet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final next = _nextSession(ctx);
    final hint = next != null
        ? '\n\nUp next: **${next['title']}** in **${next['room']}**.'
        : '';
    return '$timeGreet, **$name**! I\'m your NSE conference guide — schedule, speakers, hotels, Wi-Fi, food, or Maiduguri.$hint';
  }

  String _scheduleAnswer(String q, _GuideContext ctx) {
    if (_matches(q, ['technical track', 'technical session', 'divisional'])) {
      final tech = ctx.sessions
          .where((s) => (s['track'] as String? ?? '').toLowerCase().contains('technical'))
          .toList();
      if (tech.isNotEmpty) {
        final lines = tech.take(4).map((s) => '• **${s['title']}** — ${s['room']}').join('\n');
        return '**Technical sessions:**\n$lines\n\nSee **Schedule** for times.';
      }
    }

    for (final room in ['grand hall', 'hall a', 'hall b', 'courtyard', 'workshop']) {
      if (q.contains(room)) {
        final inRoom = ctx.sessions
            .where((s) => (s['room'] as String? ?? '').toLowerCase().contains(room))
            .toList();
        if (inRoom.isNotEmpty) {
          final lines = inRoom.map((s) => '• **${s['title']}**').join('\n');
          return '**In ${room.toUpperCase()}:**\n$lines';
        }
      }
    }

    if (_matches(q, ['now', 'current', 'happening', 'live'])) {
      final live = _liveSession(ctx);
      if (live != null) {
        return '**Now:** ${live['title']}\n**Room:** ${live['room']}\n**Time:** ${formatTimeRange(_parse(live['starts_at'])!, _parse(live['ends_at'])!)}';
      }
    }

    if (_matches(q, ['next', 'upcoming', 'soon', 'later'])) {
      final next = _nextSession(ctx);
      if (next != null) return _sessionAnswer(next, prefix: '**Up next**');
    }

    if (_matches(q, ['today', 'this morning', 'this afternoon', 'tonight'])) {
      final today = _sessionsToday(ctx);
      if (today.isEmpty) {
        return 'Programme runs **${ctx.info.dates}**. Open **Schedule** for all ${ctx.sessions.length} sessions.';
      }
      final lines = today.map((s) => '• **${s['title']}** — ${s['room']}').join('\n');
      return '**Today\'s sessions:**\n$lines';
    }

    if (_matches(q, ['opening', 'keynote', 'ceremony'])) {
      final s = ctx.sessions
          .where((s) => (s['title'] as String).toLowerCase().contains('opening'))
          .firstOrNull;
      if (s != null) return _sessionAnswer(s);
    }

    if (_matches(q, ['closing', 'awards'])) {
      final s = ctx.sessions
          .where((s) => (s['title'] as String).toLowerCase().contains('closing'))
          .firstOrNull;
      if (s != null) return _sessionAnswer(s);
    }

    final next = _nextSession(ctx);
    if (next != null) {
      return '${_sessionAnswer(next, prefix: '**Next session**')}\n\nOpen **Schedule** for all ${ctx.sessions.length} sessions.';
    }
    return 'Open **Schedule** for the full programme (${ctx.info.dates}).';
  }

  String _speakersAnswer(String q, _GuideContext ctx) {
    if (_matches(q, ['keynote', 'chairman', 'opening'])) {
      final keynotes = ctx.speakers.where((s) => s['is_keynote'] == true).toList();
      if (keynotes.isNotEmpty) {
        final lines = keynotes
            .map((s) => '• **${s['name']}** — ${s['title']}, ${s['company']}')
            .join('\n');
        return '**Keynote speakers:**\n$lines\n\nOpen **Speakers** for bios.';
      }
    }

    final match = _matchSpeaker(q, ctx.speakers);
    if (match != null) return _speakerAnswer(match, ctx);

    final preview = ctx.speakers.take(3).map((s) => '• ${s['name']}').join('\n');
    return '**${ctx.speakers.length} speakers** including:\n$preview\n\nAsk *"Who is Engr. Wanori?"* or open **Speakers**.';
  }

  String _venueAnswer(_GuideContext ctx) {
    final dirs = (ctx.pois['directions'] as List?)?.cast<String>() ?? [];
    final dirText = dirs.take(2).map((d) => '• $d').join('\n');
    return '**${EventConfig.venueName}**\n${EventConfig.venueAddress}\n\n$dirText\n\n${ctx.pois['parking'] ?? ''}\n\nUse **Venue map** in the app.';
  }

  String _hotelsAnswer(_GuideContext ctx) {
    final appHotels = ctx.hotels.take(3).map((h) => '• **${h.shortName}** — ${h.distanceToVenue}').join('\n');
    return '**${ctx.hotels.length} delegate hotels** listed.\n\n$appHotels\n\nOpen **Hotels** for rates and booking. ${ctx.pois['shuttle'] ?? ''}';
  }

  String _emergencyAnswer(_GuideContext ctx) {
    final lines = ctx.emergency
        .take(4)
        .map((e) => '• **${e['label']}**: ${e['phone']}')
        .join('\n');
    return '**Emergency contacts:**\n$lines\n\nFull list in **Emergency**. Hotline: **${EventConfig.primaryHotline}**.';
  }

  String _foodAnswer(_GuideContext ctx) {
    if (ctx.menu.isEmpty) {
      return 'Meals at ICC catering points. Order via **Concierge** → Food orders.';
    }
    final items = ctx.menu.take(5).map((m) => '• ${m['name']}').join('\n');
    return '**Available now:**\n$items\n\nOrder in **Concierge** → Food orders.';
  }

  String _announcementsAnswer(_GuideContext ctx) {
    if (ctx.announcements.isEmpty) {
      return 'No announcements yet. Check **Activity** during the conference.';
    }
    final latest = ctx.announcements.first;
    final more = ctx.announcements.length > 1
        ? '\n\n+ ${ctx.announcements.length - 1} more in **Announcements**.'
        : '';
    return '**Latest:** ${latest['title']}\n${latest['body']}$more';
  }

  String _maiduguriAnswer(_GuideContext ctx) {
    final nearby = (ctx.pois['nearby'] as List?) ?? [];
    final spots = nearby
        .take(4)
        .map((p) => '• **${p['name']}** (${p['category']}) — ${p['distance']}')
        .join('\n');
    return '**Maiduguri guide** covers directions, shuttles, and local spots:\n\n$spots\n\nOpen **Maiduguri guide** in the app.';
  }

  String _sessionAnswer(Map<String, dynamic> s, {String? prefix}) {
    final start = _parse(s['starts_at'] as String?);
    final end = _parse(s['ends_at'] as String?);
    final when = start != null && end != null ? formatTimeRange(start, end) : '';
    final day = start != null ? formatDayLabel(start.toLocal()) : '';
    final head = prefix ?? '**${s['title']}**';
    return '$head\n**Room:** ${s['room']}\n**When:** $day · $when\n\n${s['description'] ?? ''}\n\nOpen **Schedule** for details.';
  }

  String _speakerAnswer(Map<String, dynamic> s, _GuideContext ctx) {
    final titles = ctx.sessionTitlesForSpeaker(s['id'] as String);
    final sessLine =
        titles.isEmpty ? '' : '\n\n**Sessions:** ${titles.join(', ')}.';
    return '**${s['name']}**\n${s['title']}, ${s['company']}\n\n${s['bio']}$sessLine';
  }

  String _smartFallback(
    String q,
    String? userName,
    List<String> hints,
    List<FaqItem> relatedFaqs,
  ) {
    if (_matches(q, ['help', 'what can', 'how do'])) return _help(userName);

    final topicHints = hints
        .where((h) => h != '__faq__')
        .map((h) => '*${_intentLabel(h)}*')
        .toList();

    final faqHints = relatedFaqs
        .take(2)
        .map((f) => '*${f.question}*')
        .toList();

    final allHints = [...topicHints, ...faqHints].take(4).join(', ');
    final hintLine = allHints.isNotEmpty ? '\n\nDid you mean: $allHints?' : '';

    return 'I couldn\'t find an exact match. Try:\n'
        '• *"What\'s next?"* · *"Wi-Fi password?"*\n'
        '• *"Who is Engr. Wanori?"* · *"Hotels near ICC?"*\n'
        '• Tap **FAQs** for 40 quick answers$hintLine';
  }

  String _enrich(String answer, _GuideContext ctx, String intent) {
    if (intent == 'schedule') {
      final live = _liveSession(ctx);
      if (live != null && !answer.toLowerCase().contains('live')) {
        return '$answer\n\n**Live now:** ${live['title']} in ${live['room']}.';
      }
    }
    return answer;
  }

  String _help(String? userName) {
    final name = userName != null ? ' ${greetingFirstName(userName)}' : '';
    return 'Hi$name! Ask about **NSE \'26** — or tap **FAQs** for 40 ready answers on registration, venue, hotels, Wi-Fi, food, and more.';
  }

  String _intentLabel(String intent) => switch (intent) {
        'schedule' => 'schedule',
        'speakers' => 'speakers',
        'hotels' => 'hotels',
        'wifi' => 'Wi-Fi',
        'emergency' => 'emergency',
        'food' => 'food',
        'venue' => 'venue',
        'maiduguri' => 'Maiduguri',
        _ => intent,
      };

  void _boostFromEntities(String q, _GuideContext ctx, void Function(String, double) bump) {
    for (final s in ctx.speakers) {
      if (_tokenOverlap(q, (s['name'] as String).toLowerCase()) >= 2) bump('speakers', 4);
    }
    for (final s in ctx.sessions) {
      if (_tokenOverlap(q, (s['title'] as String).toLowerCase()) >= 2) bump('schedule', 4);
    }
  }

  Map<String, dynamic>? _matchSpeaker(String q, List<Map<String, dynamic>> speakers) {
    Map<String, dynamic>? best;
    var bestScore = 0.0;
    for (final s in speakers) {
      final name = (s['name'] as String).toLowerCase();
      var score = _tokenOverlap(q, name).toDouble();
      for (final part in name.split(' ')) {
        if (part.length > 3) score += GuideNlp.fuzzyContains(q, part);
      }
      if (score > bestScore) {
        bestScore = score;
        best = s;
      }
    }
    return bestScore >= 2 ? best : null;
  }

  Map<String, dynamic>? _matchSession(String q, List<Map<String, dynamic>> sessions) {
    Map<String, dynamic>? best;
    var bestScore = 0.0;
    for (final s in sessions) {
      final title = (s['title'] as String).toLowerCase();
      var score = _tokenOverlap(q, title).toDouble();
      for (final part in title.split(' ')) {
        if (part.length > 4) score += GuideNlp.fuzzyContains(q, part) * 0.5;
      }
      if (score > bestScore) {
        bestScore = score;
        best = s;
      }
    }
    return bestScore >= 2 ? best : null;
  }

  Map<String, dynamic>? _nextSession(_GuideContext ctx) {
    final now = DateTime.now().toUtc();
    for (final s in ctx.sessions) {
      final start = _parse(s['starts_at'] as String?);
      if (start != null && start.isAfter(now)) return s;
    }
    return ctx.sessions.isNotEmpty ? ctx.sessions.first : null;
  }

  Map<String, dynamic>? _liveSession(_GuideContext ctx) {
    final now = DateTime.now().toUtc();
    for (final s in ctx.sessions) {
      final start = _parse(s['starts_at'] as String?);
      final end = _parse(s['ends_at'] as String?);
      if (start != null && end != null && !now.isBefore(start) && now.isBefore(end)) {
        return s;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _sessionsToday(_GuideContext ctx) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ctx.sessions.where((s) {
      final start = _parse(s['starts_at'] as String?);
      if (start == null) return false;
      final d = DateTime(start.year, start.month, start.day);
      return d == today;
    }).toList();
  }

  DateTime? _parse(String? iso) => iso == null ? null : DateTime.tryParse(iso)?.toUtc();

  bool _matches(String q, List<String> terms) => terms.any(q.contains);

  double _score(String q, List<String> terms) {
    var total = 0.0;
    for (final t in terms) {
      if (q.contains(t)) {
        total += t.contains(' ') ? 2.5 : 1.0;
      } else {
        total += GuideNlp.fuzzyContains(q, t) * 0.9;
      }
    }
    return total;
  }

  int _tokenOverlap(String a, String b) {
    final ta = a.split(' ').where((w) => w.length > 2).toSet();
    final tb = b.split(' ').where((w) => w.length > 2).toSet();
    return ta.intersection(tb).length;
  }

  static const _intents = <String, List<String>>{
    'greeting': ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'sannu', 'how far'],
    'schedule': [
      'schedule', 'programme', 'program', 'session', 'agenda', 'whats on',
      "what's on", 'up next', 'next session', 'happening now', 'today',
      'opening', 'keynote', 'closing', 'workshop', 'panel',
    ],
    'speakers': ['speaker', 'speakers', 'who is', "who's", 'presenter', 'keynote', 'chairman', 'wanori', 'bello'],
    'dates': ['when', 'date', 'dates', 'how long', 'start', 'end', 'november', 'december'],
    'venue': ['venue', 'icc', 'conference centre', 'conference center', 'where is', 'location', 'address', 'directions'],
    'hotels': ['hotel', 'hotels', 'accommodation', 'lodging', 'stay', 'room', 'shuttle'],
    'wifi': ['wifi', 'wi-fi', 'wi fi', 'internet', 'password', 'ssid', 'network'],
    'emergency': ['emergency', 'medical', 'first aid', 'security', 'hotline', 'ambulance', '112'],
    'theme': ['theme', 'about nse', 'nigerian society', 'chairman', 'organization'],
    'food': ['food', 'lunch', 'breakfast', 'dinner', 'menu', 'eat', 'catering', 'order food', 'snack'],
    'concierge': ['concierge', 'usher', 'badge', 'registration', 'lost', 'wheelchair', 'assistance', 'help desk'],
    'networking': ['networking', 'delegate', 'connect', 'chat', 'message', 'meet people'],
    'announcements': ['announcement', 'announcements', 'news', 'update', 'latest', 'notice'],
    'entertainment': ['cultural', 'entertainment', 'night', 'performance', 'music', 'band'],
    'spouses': ['spouse', 'spouses', 'partner', 'family programme', 'family program'],
    'maiduguri': ['maiduguri', 'borno', 'city', 'nearby', 'restaurant', 'atm', 'market', 'tourist'],
    'map': ['map', 'floor plan', 'hall', 'room finder'],
    'agenda': ['my agenda', 'saved', 'bookmark'],
  };
}

class _GuideContext {
  _GuideContext({
    required this.info,
    required this.pois,
    required this.hotels,
    required this.sessions,
    required this.speakers,
    required this.sessionSpeakers,
    required this.announcements,
    required this.emergency,
    required this.menu,
  });

  final ConferenceInfo info;
  final Map<String, dynamic> pois;
  final List<ReferenceHotel> hotels;
  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> speakers;
  final List<Map<String, dynamic>> sessionSpeakers;
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> emergency;
  final List<Map<String, dynamic>> menu;

  List<String> sessionTitlesForSpeaker(String speakerId) {
    final sessionIds = sessionSpeakers
        .where((r) => r['speaker_id'] == speakerId)
        .map((r) => r['session_id'] as String)
        .toSet();
    return sessions
        .where((s) => sessionIds.contains(s['id']))
        .map((s) => s['title'] as String)
        .toList();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
