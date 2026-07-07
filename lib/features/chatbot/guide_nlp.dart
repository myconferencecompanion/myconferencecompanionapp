/// Natural-language helpers for the conference guide.
class GuideTurn {
  const GuideTurn({required this.user, required this.text, this.intent});

  final bool user;
  final String text;
  final String? intent;
}

class GuideNlp {
  static const _synonyms = <String, List<String>>{
    'wifi': ['wi fi', 'wi-fi', 'internet', 'wlan', 'hotspot', 'network'],
    'hotel': ['hotels', 'accommodation', 'lodging', 'stay', 'room', 'sleep'],
    'schedule': ['programme', 'program', 'agenda', 'timetable', 'sessions', 'calendar'],
    'food': ['meal', 'meals', 'lunch', 'breakfast', 'dinner', 'menu', 'eat', 'catering'],
    'venue': ['icc', 'location', 'address', 'directions', 'where', 'place'],
    'emergency': ['help', 'urgent', 'medical', 'ambulance', 'hospital', '112'],
    'speaker': ['speakers', 'presenter', 'keynote', 'chairman', 'panelist'],
    'next': ['upcoming', 'soon', 'later', 'after', 'following'],
    'badge': ['registration', 'check in', 'checkin', 'credential', 'pass'],
    'shuttle': ['bus', 'transport', 'pickup', 'ride'],
    'map': ['floor plan', 'floorplan', 'navigation', 'find room'],
  };

  static const _followUpStarts = [
    'and ',
    'what about ',
    'how about ',
    'also ',
    'tell me more',
    'more on ',
    'more about ',
    'what of ',
    'ok and ',
  ];

  /// Expand shorthand / follow-up questions using recent chat.
  static String expandQuery(String question, List<GuideTurn> history, String? lastTopic) {
    var q = question.trim();
    final lower = q.toLowerCase();

    if (_isFollowUp(lower) && history.isNotEmpty) {
      final lastUser = history.reversed.where((m) => m.user).map((m) => m.text).firstOrNull;
      if (lastUser != null && q.length < 50) {
        q = '$lastUser — also: $q';
      } else if (lastTopic != null) {
        q = '$lastTopic $q';
      }
    }

    if (_isPronounFollowUp(lower) && history.isNotEmpty) {
      final lastBot = history.reversed.where((m) => !m.user).map((m) => m.text).firstOrNull;
      final lastUser = history.reversed.where((m) => m.user).map((m) => m.text).firstOrNull;
      if (lastUser != null) q = '$lastUser $q';
      if (lastBot != null && lower.contains('time')) {
        q = '$q schedule time';
      }
    }

    return q;
  }

  static String normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r"[^\w\s']"), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    for (final e in _synonyms.entries) {
      for (final alt in e.value) {
        if (s.contains(alt)) {
          s = s.replaceAll(alt, e.key);
        }
      }
    }
    return s;
  }

  static bool isSocial(String q) {
    return _matchesAny(q, [
      'thank',
      'thanks',
      'thx',
      'appreciate',
      'cheers',
      'bye',
      'goodbye',
      'see you',
      'cool',
      'great',
      'perfect',
      'awesome',
      'got it',
      'understood',
      'ok thanks',
      'nice one',
    ]);
  }

  static String? socialReply(String q, String? userName) {
    final n = normalize(q);
    if (_matchesAny(n, ['thank', 'thanks', 'thx', 'appreciate', 'cheers', 'nice one'])) {
      final name = userName?.trim();
      final hi = (name != null && name.isNotEmpty) ? ' $name' : '';
      return 'You\'re welcome$hi! Ask anytime — schedule, hotels, Wi-Fi, food, or Maiduguri tips.';
    }
    if (_matchesAny(n, ['bye', 'goodbye', 'see you'])) {
      return 'Safe travels and enjoy **NSE \'26**! I\'m here whenever you need conference help.';
    }
    if (_matchesAny(n, ['cool', 'great', 'perfect', 'awesome', 'got it', 'understood'])) {
      return 'Glad that helped. What else can I look up for you?';
    }
    return null;
  }

  static bool isCompound(String q) =>
      q.contains(' and ') || q.contains(' & ') || q.contains(' plus ');

  static List<String> splitCompound(String q) {
    if (!isCompound(q)) return [q];
    return q
        .split(RegExp(r'\s+and\s+|\s*&\s*|\s+plus\s+', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static int fuzzyContains(String haystack, String needle) {
    if (needle.length < 4) return haystack.contains(needle) ? 1 : 0;
    if (haystack.contains(needle)) return 2;

    final words = haystack.split(' ');
    var best = 0;
    for (final w in words) {
      if (w.length < 4) continue;
      final d = _levenshtein(w, needle);
      if (d <= 1 && needle.length >= 5) {
        best = 2;
      } else if (d <= 2 && needle.length >= 6) {
        best = 1;
      }
    }
    return best;
  }

  static bool _isFollowUp(String lower) =>
      _followUpStarts.any(lower.startsWith) || lower == 'more' || lower == 'details';

  static bool _isPronounFollowUp(String lower) =>
      RegExp(r'\b(it|that|there|this)\b').hasMatch(lower) && lower.length < 40;

  static bool _matchesAny(String q, List<String> terms) =>
      terms.any((t) => q.contains(t));

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final m = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      m[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      m[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        m[i][j] = [
          m[i - 1][j] + 1,
          m[i][j - 1] + 1,
          m[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return m[a.length][b.length];
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
