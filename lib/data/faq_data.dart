import 'dart:convert';

import 'package:flutter/services.dart';

class FaqItem {
  FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.keywords,
  });

  final String id;
  final String category;
  final String question;
  final String answer;
  final List<String> keywords;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as String,
      category: json['category'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      keywords: (json['keywords'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class FaqData {
  static List<FaqItem>? _cache;

  static Future<List<FaqItem>> all() async {
    _cache ??= await _load();
    return _cache!;
  }

  static Future<Map<String, List<FaqItem>>> byCategory() async {
    final items = await all();
    final map = <String, List<FaqItem>>{};
    for (final f in items) {
      map.putIfAbsent(f.category, () => []).add(f);
    }
    return map;
  }

  static Future<(FaqItem?, double)> bestMatch(String question) async {
    final q = _normalize(question);
    if (q.isEmpty) return (null, 0.0);

    FaqItem? best;
    var bestScore = 0.0;

    for (final faq in await all()) {
      final score = _faqScore(q, faq);
      if (score > bestScore) {
        bestScore = score;
        best = faq;
      }
    }
    return (best, bestScore);
  }

  /// Best FAQ match for a user question, or null if confidence is low.
  static Future<FaqItem?> match(String question, {double minScore = 3}) async {
    final (item, score) = await bestMatch(question);
    return score >= minScore ? item : null;
  }

  static Future<List<FaqItem>> search(String query, {int limit = 8}) async {
    final q = _normalize(query);
    if (q.isEmpty) return (await all()).take(limit).toList();

    final scored = <(FaqItem, double)>[];
    for (final faq in await all()) {
      final score = _faqScore(q, faq);
      if (score > 0) scored.add((faq, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(limit).map((e) => e.$1).toList();
  }

  static double _faqScore(String q, FaqItem faq) {
    var score = 0.0;
    final question = _normalize(faq.question);

    score += _tokenOverlap(q, question) * 2.5;

    if (q == question) score += 10;
    if (question.contains(q) && q.length > 8) score += 6;
    if (q.contains(question) && question.length > 12) score += 5;

    for (final kw in faq.keywords) {
      final k = _normalize(kw);
      if (k.isEmpty) continue;
      if (q.contains(k)) score += k.contains(' ') ? 2.5 : 1.5;
    }

    for (final word in q.split(' ')) {
      if (word.length < 4) continue;
      if (question.contains(word)) score += 0.8;
    }

    return score;
  }

  static String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r"[^\w\s']"), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static int _tokenOverlap(String a, String b) {
    final ta = a.split(' ').where((w) => w.length > 2).toSet();
    final tb = b.split(' ').where((w) => w.length > 2).toSet();
    return ta.intersection(tb).length;
  }

  static Future<List<FaqItem>> _load() async {
    final raw = await rootBundle.loadString('assets/data/faqs.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => FaqItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
