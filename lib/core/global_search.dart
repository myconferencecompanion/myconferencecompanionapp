import 'package:flutter/material.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/admin_config.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/data/faq_data.dart';
import 'package:nse_mobile/data/reference_data.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class SearchHit {
  const SearchHit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.group,
    required this.icon,
    required this.iconColor,
    required this.iconTone,
    required this.route,
    this.faqAnswer,
    required this.searchText,
  });

  final String id;
  final String title;
  final String subtitle;
  final String group;
  final IconData icon;
  final Color iconColor;
  final Color iconTone;
  final String route;
  final String? faqAnswer;
  final List<String> searchText;
}

class GlobalSearch {
  GlobalSearch._();

  static List<SearchHit>? _index;

  static const quickQueries = [
    'Wi-Fi password',
    'Food menu',
    'Today\'s schedule',
    'Emergency numbers',
    'Hotels near ICC',
    'Shuttle times',
    'Conference Guide',
  ];

  static Future<void> warmIndex(dynamic client, {bool includeAdmin = false}) async {
    _index ??= await _buildIndex(client, includeAdmin: includeAdmin);
  }

  static Future<List<SearchHit>> query(
    String raw, {
    required dynamic client,
    bool includeAdmin = false,
    int limit = 40,
  }) async {
    await warmIndex(client, includeAdmin: includeAdmin);
    final q = _normalize(raw);
    if (q.isEmpty) return [];

    final scored = <(SearchHit, double)>[];
    for (final hit in _index!) {
      final score = _score(q, hit);
      if (score > 0) scored.add((hit, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(limit).map((e) => e.$1).toList();
  }

  static Future<List<SearchHit>> browse({
    required dynamic client,
    bool includeAdmin = false,
  }) async {
    await warmIndex(client, includeAdmin: includeAdmin);
    return _index!.take(12).toList();
  }

  static Future<List<SearchHit>> _buildIndex(
    dynamic client, {
    required bool includeAdmin,
  }) async {
    final hits = <SearchHit>[];

    void add({
      required String id,
      required String title,
      required String subtitle,
      required String group,
      required IconData icon,
      required Color iconColor,
      required Color iconTone,
      required String route,
      String? faqAnswer,
      List<String> extra = const [],
    }) {
      hits.add(
        SearchHit(
          id: id,
          title: title,
          subtitle: subtitle,
          group: group,
          icon: icon,
          iconColor: iconColor,
          iconTone: iconTone,
          route: route,
          faqAnswer: faqAnswer,
          searchText: [title, subtitle, group, ...extra],
        ),
      );
    }

    const appLinks = [
      ('app-schedule', 'Schedule', 'Sessions, times, and rooms', '/schedule', Icons.calendar_month_rounded, AppColors.navy, AppColors.navySoft, ['programme', 'agenda', 'timetable']),
      ('app-speakers', 'Speakers', 'Keynotes and panelists', '/speakers', Icons.mic_rounded, AppColors.green, AppColors.greenSoft, ['presenters', 'chairman']),
      ('app-agenda', 'My agenda', 'Saved sessions', '/agenda', Icons.bookmark_rounded, AppColors.gold, AppColors.goldSoft, ['bookmarks']),
      ('app-concierge', 'Concierge', 'Usher, food, errands', '/concierge', Icons.room_service_rounded, AppColors.gold, AppColors.goldSoft, ['help', 'service']),
      ('app-transport', 'My transport', 'Bus assignment and shuttle times', '/transport', Icons.directions_bus_rounded, AppColors.green, AppColors.greenSoft, ['shuttle', 'bus', 'marshal']),
      ('app-food', 'Food orders', 'Complimentary delegate meals', '/concierge/food', Icons.restaurant_rounded, AppColors.gold, AppColors.goldSoft, ['menu', 'lunch', 'breakfast', 'catering']),
      ('app-usher', 'Call an usher', 'Front desk assistance', '/concierge/usher', Icons.support_agent_rounded, AppColors.navy, AppColors.navySoft, ['security', 'badge', 'help']),
      ('app-errands', 'Errands', 'Laundry, printing, and more', '/concierge/errands', Icons.local_laundry_service_rounded, AppColors.navy, AppColors.navySoft, []),
      ('app-orders', 'My food orders', 'Track meal pickup', '/concierge/orders', Icons.receipt_long_rounded, AppColors.gold, AppColors.goldSoft, []),
      ('app-hotels', 'Hotels', 'Partner accommodation', '/accommodation', Icons.hotel_rounded, AppColors.gold, AppColors.goldSoft, ['lodging', 'room']),
      ('app-maidguide', 'Maiduguri guide', 'City tips and POIs', '/maidguide', Icons.explore_rounded, AppColors.green, AppColors.greenSoft, ['city', 'local']),
      ('app-nearby', 'Nearby places', 'Restaurants, ATMs, pharmacy', '/nearby', Icons.place_rounded, AppColors.green, AppColors.greenSoft, ['maps']),
      ('app-directions', 'Directions to ICC', 'Airport and city routes', '/directions', Icons.directions_rounded, AppColors.navy, AppColors.navySoft, ['map', 'venue']),
      ('app-map', 'Venue map', 'ICC rooms and halls', '/map', Icons.map_rounded, AppColors.navy, AppColors.navySoft, ['icc', 'floor plan']),
      ('app-emergency', 'Emergency', 'Medical and security contacts', '/emergency', Icons.health_and_safety_rounded, AppColors.destructive, AppColors.destructiveSoft, ['safety', 'hotline', '112']),
      ('app-announcements', 'Announcements', 'Latest conference news', '/announcements', Icons.campaign_rounded, AppColors.gold, AppColors.goldSoft, ['updates', 'news']),
      ('app-network', 'Networking', 'Chat rooms and DMs', '/network', Icons.groups_rounded, AppColors.green, AppColors.greenSoft, ['chat', 'delegates']),
      ('app-profile', 'My profile', 'Edit your delegate card', '/profile', Icons.person_rounded, AppColors.navy, AppColors.navySoft, ['account']),
      ('app-chatbot', 'Conference Guide', 'Ask anything — 40 FAQs', '/chatbot', Icons.auto_awesome_rounded, AppColors.navy, AppColors.navySoft, ['faq', 'bot', 'help', 'assistant']),
      ('app-about', 'About NSE', 'Conference theme and info', '/about', Icons.info_rounded, AppColors.navy, AppColors.navySoft, []),
      ('app-activity', 'Activity', 'Usher, food, and errand status', '/waitlist', Icons.notifications_active_rounded, AppColors.gold, AppColors.goldSoft, ['notifications']),
    ];

    for (final link in appLinks) {
      add(
        id: link.$1,
        title: link.$2,
        subtitle: link.$3,
        group: 'App',
        icon: link.$5,
        iconColor: link.$6,
        iconTone: link.$7,
        route: link.$4,
        extra: List<String>.from(link.$8),
      );
    }

    add(
      id: 'wifi',
      title: 'Conference Wi-Fi',
      subtitle: sanitizeDisplay('${EventConfig.wifiSsid} · password ${EventConfig.wifiPassword}'),
      group: 'Essentials',
      icon: Icons.wifi_rounded,
      iconColor: AppColors.gold,
      iconTone: AppColors.goldSoft,
      route: '/more',
      extra: ['internet', 'network', 'password', EventConfig.wifiSsid, EventConfig.wifiPassword],
    );

    add(
      id: 'venue',
      title: sanitizeDisplay(EventConfig.venueName),
      subtitle: sanitizeDisplay('${EventConfig.venueAddress} · ${EventConfig.dates}'),
      group: 'Essentials',
      icon: Icons.location_city_rounded,
      iconColor: AppColors.navy,
      iconTone: AppColors.navySoft,
      route: '/directions',
      extra: ['icc', 'maiduguri', 'venue', EventConfig.dates, EventConfig.tagline],
    );

    final results = await Future.wait<dynamic>([
      client.from('sessions').select().order('starts_at'),
      client.from('speakers').select().order('name'),
      client.from('announcements').select().order('created_at', ascending: false).limit(30),
      client.from('accommodations').select().order('name'),
      client.from('emergency_contacts').select().order('sort_order'),
      client.from('menu_items').select().eq('is_available', true).order('sort_order'),
      client.from('profiles').select().eq('networking_opt_in', true).limit(80),
      FaqData.all(),
      ReferenceData.hotels(),
      ReferenceData.maiduguriPois(),
      ReferenceData.conferenceInfo(),
    ]);

    final sessions = (results[0] as List).cast<Map<String, dynamic>>();
    final speakers = (results[1] as List).cast<Map<String, dynamic>>();
    final announcements = (results[2] as List).cast<Map<String, dynamic>>();
    final accommodations = (results[3] as List).cast<Map<String, dynamic>>();
    final emergency = (results[4] as List).cast<Map<String, dynamic>>();
    final menu = (results[5] as List).cast<Map<String, dynamic>>();
    final profiles = (results[6] as List).cast<Map<String, dynamic>>();
    final faqs = results[7] as List<FaqItem>;
    final refHotels = results[8] as List<ReferenceHotel>;
    final pois = results[9] as Map<String, dynamic>;
    final info = results[10] as ConferenceInfo;

    for (final s in sessions) {
      final title = s['title'] as String? ?? 'Session';
      final room = s['room'] as String? ?? '';
      add(
        id: 'session-${s['id']}',
        title: sanitizeDisplay(title),
        subtitle: sanitizeDisplay([if (s['day'] != null) 'Day ${s['day']}', room].where((e) => e.toString().isNotEmpty).join(' · ')),
        group: 'Programme',
        icon: Icons.event_rounded,
        iconColor: AppColors.navy,
        iconTone: AppColors.navySoft,
        route: '/schedule/${s['id']}',
        extra: [(s['description'] as String?) ?? '', room, 'session', 'schedule'],
      );
    }

    for (final sp in speakers) {
      add(
        id: 'speaker-${sp['id']}',
        title: sanitizeDisplay(sp['name'] as String? ?? 'Speaker'),
        subtitle: sanitizeDisplay(sp['title'] as String? ?? sp['company'] as String? ?? 'Speaker'),
        group: 'People',
        icon: Icons.mic_rounded,
        iconColor: AppColors.green,
        iconTone: AppColors.greenSoft,
        route: '/speakers/${sp['id']}',
        extra: [(sp['bio'] as String?) ?? '', 'speaker', 'keynote'],
      );
    }

    for (final a in announcements) {
      add(
        id: 'ann-${a['id']}',
        title: sanitizeDisplay(a['title'] as String? ?? 'Announcement'),
        subtitle: sanitizeDisplay((a['body'] as String? ?? '').replaceAll('\n', ' ')),
        group: 'News',
        icon: Icons.campaign_rounded,
        iconColor: AppColors.gold,
        iconTone: AppColors.goldSoft,
        route: '/announcements',
        extra: ['announcement', 'update'],
      );
    }

    for (final h in accommodations) {
      add(
        id: 'hotel-${h['id']}',
        title: sanitizeDisplay(h['name'] as String? ?? 'Hotel'),
        subtitle: sanitizeDisplay(h['address'] as String? ?? h['notes'] as String? ?? 'Partner hotel'),
        group: 'Hotels',
        icon: Icons.hotel_rounded,
        iconColor: AppColors.gold,
        iconTone: AppColors.goldSoft,
        route: '/accommodation',
        extra: ['accommodation', 'lodging'],
      );
    }

    for (final h in refHotels) {
      add(
        id: 'ref-hotel-${h.id}',
        title: h.name,
        subtitle: '#${h.rank} ${h.tierLabel} · ${h.shortName}',
        group: 'Hotels',
        icon: Icons.hotel_rounded,
        iconColor: AppColors.gold,
        iconTone: AppColors.goldSoft,
        route: '/accommodation/${h.id}',
        extra: [h.shortName, h.tone, h.description, ...h.highlights],
      );
    }

    for (final e in emergency) {
      add(
        id: 'em-${e['id']}',
        title: e['label'] as String? ?? 'Contact',
        subtitle: '${e['phone'] ?? ''} · ${e['category'] ?? 'emergency'}',
        group: 'Emergency',
        icon: Icons.phone_rounded,
        iconColor: AppColors.destructive,
        iconTone: AppColors.destructiveSoft,
        route: '/emergency',
        extra: [(e['description'] as String?) ?? '', 'medical', 'security'],
      );
    }

    for (final m in menu) {
      add(
        id: 'menu-${m['id']}',
        title: sanitizeDisplay(m['name'] as String? ?? 'Menu item'),
        subtitle: sanitizeDisplay(m['description'] as String? ?? 'Delegate meal'),
        group: 'Food',
        icon: Icons.restaurant_rounded,
        iconColor: AppColors.gold,
        iconTone: AppColors.goldSoft,
        route: '/concierge/food',
        extra: ['food', 'catering', 'lunch', 'breakfast'],
      );
    }

    for (final p in profiles) {
      final name = p['display_name'] as String? ?? 'Delegate';
      add(
        id: 'profile-${p['id']}',
        title: sanitizeDisplay(name),
        subtitle: sanitizeDisplay([p['title'], p['company']].whereType<String>().where((s) => s.isNotEmpty).join(' · ')),
        group: 'Delegates',
        icon: Icons.person_rounded,
        iconColor: AppColors.green,
        iconTone: AppColors.greenSoft,
        route: '/network/user/${p['id']}',
        extra: [(p['bio'] as String?) ?? '', 'networking', 'delegate'],
      );
    }

    for (final faq in faqs) {
      add(
        id: faq.id,
        title: faq.question,
        subtitle: faq.category,
        group: 'FAQs',
        icon: Icons.quiz_outlined,
        iconColor: AppColors.navy,
        iconTone: AppColors.navySoft,
        route: '/chatbot',
        faqAnswer: faq.answer,
        extra: [faq.answer, ...faq.keywords],
      );
    }

    final shuttle = pois['shuttle'] as String?;
    if (shuttle != null) {
      add(
        id: 'poi-shuttle',
        title: 'Delegate shuttle',
        subtitle: shuttle,
        group: 'Maiduguri',
        icon: Icons.directions_bus_rounded,
        iconColor: AppColors.green,
        iconTone: AppColors.greenSoft,
        route: '/maidguide',
        extra: ['transport', 'bus', 'hotel'],
      );
    }

    final parking = pois['parking'] as String?;
    if (parking != null) {
      add(
        id: 'poi-parking',
        title: 'ICC parking',
        subtitle: parking,
        group: 'Maiduguri',
        icon: Icons.local_parking_rounded,
        iconColor: AppColors.green,
        iconTone: AppColors.greenSoft,
        route: '/maidguide',
        extra: ['car', 'vehicle'],
      );
    }

    for (final d in (pois['directions'] as List? ?? [])) {
      add(
        id: 'dir-${d.hashCode}',
        title: 'Getting to ICC',
        subtitle: d.toString(),
        group: 'Maiduguri',
        icon: Icons.directions_rounded,
        iconColor: AppColors.navy,
        iconTone: AppColors.navySoft,
        route: '/directions',
        extra: ['airport', 'route', 'directions'],
      );
    }

    for (final n in (pois['nearby'] as List? ?? [])) {
      final map = Map<String, dynamic>.from(n as Map);
      add(
        id: 'nearby-${map['name']}',
        title: map['name'] as String? ?? 'Place',
        subtitle: '${map['category']} · ${map['distance']} · ${map['note'] ?? ''}',
        group: 'Nearby',
        icon: Icons.place_rounded,
        iconColor: AppColors.green,
        iconTone: AppColors.greenSoft,
        route: '/nearby',
        extra: [(map['query'] as String?) ?? '', 'maiduguri', map['category'] as String? ?? ''],
      );
    }

    add(
      id: 'conf-theme',
      title: info.conferenceTitle,
      subtitle: info.theme,
      group: 'About',
      icon: Icons.celebration_rounded,
      iconColor: AppColors.navy,
      iconTone: AppColors.navySoft,
      route: '/about',
      extra: [info.chairman, info.organizationName, info.dates, info.venue],
    );

    if (includeAdmin) {
      add(
        id: 'admin-home',
        title: 'Admin dashboard',
        subtitle: 'Staff operations hub',
        group: 'Admin',
        icon: Icons.admin_panel_settings_rounded,
        iconColor: AppColors.navy,
        iconTone: AppColors.navySoft,
        route: '/admin',
        extra: ['staff', 'kitchen', 'program', 'security'],
      );

      for (final section in adminSections) {
        for (final tool in section.tools) {
          add(
            id: 'admin-${tool.route}',
            title: tool.label,
            subtitle: section.title,
            group: 'Admin',
            icon: tool.icon,
            iconColor: AppColors.navy,
            iconTone: AppColors.navySoft,
            route: tool.route,
            extra: [section.subtitle, section.title],
          );
        }
      }
    }

    return hits;
  }

  static double _score(String q, SearchHit hit) {
    var score = 0.0;
    final blob = _normalize(hit.searchText.join(' '));

    if (blob == q) score += 20;
    if (blob.contains(q) && q.length > 3) score += 8;

    final qTokens = q.split(' ').where((w) => w.length > 1).toList();
    final blobTokens = blob.split(' ').where((w) => w.length > 1).toSet();

    for (final token in qTokens) {
      if (blobTokens.contains(token)) score += 2.5;
      if (blob.contains(token) && token.length > 3) score += 1.2;
    }

    if (_normalize(hit.title) == q) score += 12;
    if (_normalize(hit.title).startsWith(q)) score += 5;

    return score;
  }

  static String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r"[^\w\s']"), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
