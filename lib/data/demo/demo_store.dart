import 'dart:async';
import 'dart:math';

import 'package:nse_mobile/data/demo/demo_ids.dart';

/// In-memory conference data for offline demo mode.
class DemoStore {
  DemoStore._();
  static final DemoStore instance = DemoStore._();

  final _rng = Random(42);
  bool _ready = false;
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  Future<void> init() async {
    if (_ready) return;
    _seed();
    _ready = true;
  }

  List<Map<String, dynamic>> table(String name) =>
      _tables.putIfAbsent(name, () => []);

  String _id() => 'demo-${_rng.nextInt(1 << 30).toRadixString(16)}';

  void _seed() {
    final now = DateTime.now().toUtc();
    final day1 = DateTime.utc(2026, 11, 30, 8);
    final day2 = DateTime.utc(2026, 12, 1, 8);
    final day3 = DateTime.utc(2026, 12, 2, 8);
    final day4 = DateTime.utc(2026, 12, 3, 8);
    final day5 = DateTime.utc(2026, 12, 4, 8);

    _tables['speakers'] = [
      {
        'id': 'sp-1',
        'name': 'Engr. Mohammed Kabir Wanori, FNSE',
        'title': 'NSE National Chairman',
        'company': 'Nigerian Society of Engineers',
        'bio':
            'Opening the Maiduguri edition of the NSE International Conference with a focus on engineering-led national development.',
        'avatar_url': null,
        'is_keynote': true,
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sp-2',
        'name': 'Engr. Amina Bello',
        'title': 'Commissioner for Works',
        'company': 'Borno State Government',
        'bio': 'Infrastructure resilience and public works in the North East.',
        'avatar_url': null,
        'is_keynote': false,
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sp-3',
        'name': 'Prof. Chukwuemeka Nwankwo',
        'title': 'Dean, Faculty of Engineering',
        'company': 'University of Maiduguri',
        'bio': 'Research partnerships and engineering education.',
        'avatar_url': null,
        'is_keynote': false,
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sp-4',
        'name': 'Engr. Fatima Yusuf',
        'title': 'MD, Grid Solutions',
        'company': 'Power & Energy Division',
        'bio': 'Renewable integration and grid security.',
        'avatar_url': null,
        'is_keynote': true,
        'created_at': now.toIso8601String(),
      },
    ];

    _tables['sessions'] = [
      {
        'id': 'sess-1',
        'title': 'Opening Ceremony & Keynote',
        'description': 'Welcome delegates to ICC Maiduguri and set the conference theme.',
        'day': 1,
        'track': 'Plenary',
        'room': 'Grand Hall',
        'starts_at': day1.add(const Duration(hours: 2)).toIso8601String(),
        'ends_at': day1.add(const Duration(hours: 4)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-2',
        'title': 'Infrastructure Security Panel',
        'description': 'Panel on resilient infrastructure in challenging environments.',
        'day': 1,
        'track': 'Technical',
        'room': 'Hall B',
        'starts_at': day1.add(const Duration(hours: 5)).toIso8601String(),
        'ends_at': day1.add(const Duration(hours: 6, minutes: 30)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-3',
        'title': 'Young Engineers Forum',
        'description': 'Career pathways and mentorship for early-career engineers.',
        'day': 1,
        'track': 'Professional',
        'room': 'Workshop Room 1',
        'starts_at': day1.add(const Duration(hours: 7)).toIso8601String(),
        'ends_at': day1.add(const Duration(hours: 8)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-4',
        'title': 'Renewable Energy Workshop',
        'description': 'Hands-on discussion of solar mini-grids and hybrid systems.',
        'day': 2,
        'track': 'Technical',
        'room': 'Hall B',
        'starts_at': day2.add(const Duration(hours: 3)).toIso8601String(),
        'ends_at': day2.add(const Duration(hours: 5)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-5',
        'title': 'Cultural Night Preview',
        'description': 'Entertainment committee briefing and spouses programme.',
        'day': 2,
        'track': 'Social',
        'room': 'Courtyard',
        'starts_at': day2.add(const Duration(hours: 6)).toIso8601String(),
        'ends_at': day2.add(const Duration(hours: 7)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-6',
        'title': 'Divisional Technical Sessions',
        'description': 'Parallel tracks across NSE divisions.',
        'day': 3,
        'track': 'Technical',
        'room': 'Hall A',
        'starts_at': day3.add(const Duration(hours: 3)).toIso8601String(),
        'ends_at': day3.add(const Duration(hours: 5)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-7',
        'title': 'Branch Chairmen Roundtable',
        'description': 'Governance and membership growth across branches.',
        'day': 3,
        'track': 'Professional',
        'room': 'Grand Hall',
        'starts_at': day3.add(const Duration(hours: 5, minutes: 30)).toIso8601String(),
        'ends_at': day3.add(const Duration(hours: 7)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-8',
        'title': 'Cultural Night',
        'description': 'Live performances, guest artistes, and delegate reception.',
        'day': 4,
        'track': 'Social',
        'room': 'Courtyard',
        'starts_at': day4.add(const Duration(hours: 6)).toIso8601String(),
        'ends_at': day4.add(const Duration(hours: 9)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'sess-9',
        'title': 'Closing Ceremony & Awards',
        'description': 'Conference resolutions, awards, and formal close.',
        'day': 5,
        'track': 'Plenary',
        'room': 'Grand Hall',
        'starts_at': day5.add(const Duration(hours: 2)).toIso8601String(),
        'ends_at': day5.add(const Duration(hours: 4, minutes: 30)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
    ];

    _tables['session_speakers'] = [
      {'session_id': 'sess-1', 'speaker_id': 'sp-1'},
      {'session_id': 'sess-1', 'speaker_id': 'sp-4'},
      {'session_id': 'sess-2', 'speaker_id': 'sp-2'},
      {'session_id': 'sess-3', 'speaker_id': 'sp-3'},
      {'session_id': 'sess-4', 'speaker_id': 'sp-4'},
      {'session_id': 'sess-6', 'speaker_id': 'sp-2'},
      {'session_id': 'sess-7', 'speaker_id': 'sp-1'},
      {'session_id': 'sess-9', 'speaker_id': 'sp-1'},
    ];

    _tables['announcements'] = [
      {
        'id': 'ann-1',
        'title': 'Welcome to Maiduguri 2026',
        'body':
            'Registration desks open at ICC from 7:00 AM. Collect your badge, Wi‑Fi card, and programme booklet at the main foyer.',
        'priority': 'high',
        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'ann-2',
        'title': 'Shuttle service update',
        'body': 'Hotels on Damboa Road route: buses depart every 30 minutes from 7:30 AM.',
        'priority': 'normal',
        'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'id': 'ann-3',
        'title': 'Spouses programme',
        'body': 'University of Maiduguri cultural visit departs ICC at 10:00 AM tomorrow.',
        'priority': 'normal',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];

    _tables['emergency_contacts'] = [
      {
        'id': 'ec-1',
        'label': 'Conference emergency hotline',
        'phone': '+2348009876543',
        'description': '24/7 operations desk',
        'category': 'emergency',
        'sort_order': 1,
      },
      {
        'id': 'ec-2',
        'label': 'ICC first aid',
        'phone': '+2348000000002',
        'description': 'Hall A medical station',
        'category': 'medical',
        'sort_order': 2,
      },
      {
        'id': 'ec-3',
        'label': 'Venue security',
        'phone': '+2348000000003',
        'description': 'ICC security office',
        'category': 'security',
        'sort_order': 3,
      },
      {
        'id': 'ec-4',
        'label': 'Borno State emergency',
        'phone': '112',
        'description': 'National emergency line',
        'category': 'emergency',
        'sort_order': 0,
      },
    ];

    _tables['profiles'] = [
      {
        'id': DemoIds.delegate,
        'display_name': 'Ada Okafor',
        'title': 'Structural Engineer',
        'company': 'Lagos Branch, NSE',
        'bio': 'Attending IEC 2026 — interested in infrastructure security sessions.',
        'avatar_url': null,
        'networking_opt_in': true,
        'created_at': now.toIso8601String(),
      },
      {
        'id': DemoIds.delegate2,
        'display_name': 'Chidi Nwosu',
        'title': 'Project Manager',
        'company': 'Abuja Branch',
        'bio': 'Civil works and public procurement.',
        'avatar_url': null,
        'networking_opt_in': true,
        'created_at': now.toIso8601String(),
      },
      {
        'id': DemoIds.delegate3,
        'display_name': 'Ngozi Eze',
        'title': 'Electrical Engineer',
        'company': 'Port Harcourt Branch',
        'bio': 'Power systems and renewables.',
        'avatar_url': null,
        'networking_opt_in': true,
        'created_at': now.toIso8601String(),
      },
    ];

    _tables['accommodations'] = [
      {
        'id': 'hotel-amada',
        'name': 'Amada International Hotel',
        'address': 'Magira Road, Maiduguri',
        'distance_km': 4.2,
        'price_range': 'N47,000 – N71,500',
        'booking_url': 'https://nse.org.ng/',
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'hotel-aiba',
        'name': 'Aiba Sport Resort',
        'address': 'Maiduguri',
        'distance_km': 5.1,
        'price_range': 'Discounted delegate rates',
        'booking_url': 'https://nse.org.ng/',
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'hotel-icc',
        'name': 'ICC Partner Lodge',
        'address': 'Near International Conference Centre',
        'distance_km': 0.8,
        'price_range': 'Limited rooms',
        'booking_url': null,
        'created_at': now.toIso8601String(),
      },
    ];

    _tables['menu_categories'] = [
      {'id': 'cat-1', 'name': 'Breakfast', 'is_active': true, 'sort_order': 1, 'max_per_order': 1},
      {'id': 'cat-2', 'name': 'Lunch', 'is_active': true, 'sort_order': 2, 'max_per_order': 1},
      {'id': 'cat-3', 'name': 'Snacks & drinks', 'is_active': true, 'sort_order': 3, 'max_per_order': 1},
    ];

    _tables['menu_items'] = [
      {
        'id': 'mi-1',
        'category_id': 'cat-1',
        'name': 'Continental breakfast plate',
        'description': 'Eggs, pastry, fruit — complimentary for delegates',
        'is_available': true,
        'sort_order': 1,
        'max_per_item': 1,
      },
      {
        'id': 'mi-2',
        'category_id': 'cat-1',
        'name': 'Local breakfast',
        'description': 'Masa, kosai, tea or coffee',
        'is_available': true,
        'sort_order': 2,
        'max_per_item': 1,
      },
      {
        'id': 'mi-3',
        'category_id': 'cat-2',
        'name': 'Jollof & grilled chicken',
        'description': 'Conference lunch service',
        'is_available': true,
        'sort_order': 1,
        'max_per_item': 1,
      },
      {
        'id': 'mi-4',
        'category_id': 'cat-2',
        'name': 'Vegetarian plate',
        'description': 'Rice, vegetables, plantain',
        'is_available': true,
        'sort_order': 2,
        'max_per_item': 1,
      },
      {
        'id': 'mi-5',
        'category_id': 'cat-3',
        'name': 'Bottled water',
        'description': '500ml',
        'is_available': true,
        'sort_order': 1,
        'max_per_item': 1,
      },
      {
        'id': 'mi-6',
        'category_id': 'cat-3',
        'name': 'Fresh juice',
        'description': 'Seasonal fruit blend',
        'is_available': true,
        'sort_order': 2,
        'max_per_item': 1,
      },
    ];

    _tables['chat_rooms'] = [
      {
        'id': 'room-general',
        'name': 'General lounge',
        'description': 'Meet delegates from all branches',
        'sort_order': 1,
      },
      {
        'id': 'room-technical',
        'name': 'Technical track',
        'description': 'Infrastructure & energy discussions',
        'sort_order': 2,
      },
      {
        'id': 'room-young',
        'name': 'Young engineers',
        'description': 'Early-career networking',
        'sort_order': 3,
      },
    ];

    _tables['chat_messages'] = [
      {
        'id': 'cm-1',
        'room_id': 'room-general',
        'user_id': DemoIds.delegate2,
        'content': 'Just arrived at ICC — registration was smooth!',
        'created_at': now.subtract(const Duration(minutes: 45)).toIso8601String(),
      },
      {
        'id': 'cm-2',
        'room_id': 'room-general',
        'user_id': DemoIds.delegate3,
        'content': 'Anyone heading to the opening ceremony together?',
        'created_at': now.subtract(const Duration(minutes: 20)).toIso8601String(),
      },
      {
        'id': 'cm-3',
        'room_id': 'room-technical',
        'user_id': DemoIds.delegate2,
        'content': 'The infrastructure panel at Hall B looks great.',
        'created_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
      },
    ];

    _tables['direct_messages'] = [
      {
        'id': 'dm-1',
        'sender_id': DemoIds.delegate2,
        'recipient_id': DemoIds.delegate,
        'content': 'Hi Ada — saw your profile. Are you attending the security panel?',
        'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': 'dm-2',
        'sender_id': DemoIds.delegate,
        'recipient_id': DemoIds.delegate2,
        'content': 'Yes! See you in Hall B.',
        'created_at': now.subtract(const Duration(minutes: 50)).toIso8601String(),
      },
    ];

    _tables['usher_requests'] = [
      {
        'id': 'ur-1',
        'user_id': DemoIds.delegate,
        'reason': 'accessibility',
        'note': 'Wheelchair ramp to Hall B',
        'location_label': 'Main Lobby',
        'status': 'acknowledged',
        'created_at': now.subtract(const Duration(minutes: 15)).toIso8601String(),
      },
    ];

    _tables['food_orders'] = [
      {
        'id': 'fo-1',
        'user_id': DemoIds.delegate,
        'pickup_location': 'ICC Catering Point B',
        'notes': 'No spice',
        'status': 'preparing',
        'total_ngn': 0,
        'created_at': now.subtract(const Duration(minutes: 10)).toIso8601String(),
      },
    ];

    _tables['food_order_items'] = [
      {
        'id': 'foi-1',
        'order_id': 'fo-1',
        'menu_item_id': 'mi-3',
        'item_name_snapshot': 'Jollof & grilled chicken',
        'quantity': 1,
        'unit_price_ngn': 0,
      },
    ];

    _tables['errand_requests'] = [
      {
        'id': 'er-1',
        'user_id': DemoIds.delegate,
        'category': 'pharmacy',
        'description': 'Paracetamol and hand sanitiser',
        'accommodation_id': 'hotel-amada',
        'room_number': '204',
        'urgency': 'normal',
        'status': 'accepted',
        'created_at': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      },
    ];

    _tables['announcement_reads'] = [];
    _tables['my_agenda'] = [
      {
        'id': 'ag-1',
        'user_id': DemoIds.delegate,
        'session_id': 'sess-2',
        'created_at': now.toIso8601String(),
      },
    ];

    _tables['transport_settings'] = [
      {
        'id': 'default',
        'boarding_policy': 'hybrid',
        'updated_at': now.toIso8601String(),
      },
    ];
    _tables['transport_assignments'] = [
      {'id': 'ta-1', 'user_id': DemoIds.delegate, 'bus_id': 'bus-a', 'hotel_id': 'amada'},
      {'id': 'ta-2', 'user_id': DemoIds.delegate2, 'bus_id': 'bus-b', 'hotel_id': 'golden-sand'},
      {'id': 'ta-3', 'user_id': DemoIds.delegate3, 'bus_id': 'bus-c', 'hotel_id': 'borno-state-hotel'},
    ];
    final runBase = DateTime.utc(2026, 11, 30, 7, 30);
    _tables['transport_runs'] = [
      for (var i = 0; i < 5; i++)
        for (final bus in ['bus-a', 'bus-b', 'bus-c', 'bus-d', 'bus-e'])
          {
            'id': 'run-$bus-$i',
            'bus_id': bus,
            'label': ['Morning → ICC', 'Midday return', 'Afternoon → ICC', 'Evening return', 'Night return'][i],
            'direction': i.isEven ? 'to_venue' : 'to_hotel',
            'scheduled_at': runBase.add(Duration(hours: i * 3)).toIso8601String(),
            'status': 'scheduled',
            'locked_at': null,
          },
    ];
    _tables['transport_boardings'] = [];

    _tables['user_roles'] = [];
  }

  Future<dynamic> execute(DemoQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (query.mutation == DemoMutation.insert) {
      return _insert(query);
    }
    if (query.mutation == DemoMutation.insertMany) {
      return _insertMany(query);
    }
    if (query.mutation == DemoMutation.update) {
      return _update(query);
    }
    if (query.mutation == DemoMutation.upsert) {
      return _upsert(query);
    }
    if (query.mutation == DemoMutation.delete) {
      return _delete(query);
    }
    return _select(query);
  }

  dynamic _delete(DemoQuery query) {
    final rows = table(query.table);
    rows.removeWhere((r) => _matchesFilters(r, query.filters));
    return null;
  }

  dynamic _insert(DemoQuery query) {
    final rows = table(query.table);
    final data = Map<String, dynamic>.from(query.payload as Map);
    if (!data.containsKey('id')) data['id'] = _id();
    if (!data.containsKey('created_at')) {
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (query.table == 'food_orders' && !data.containsKey('status')) {
      data['status'] = 'pending';
    }
    if (query.table == 'usher_requests' && !data.containsKey('status')) {
      data['status'] = 'pending';
    }
    if (query.table == 'errand_requests' && !data.containsKey('status')) {
      data['status'] = 'requested';
    }
    rows.add(data);
    return _finalizeSelect([data], query);
  }

  dynamic _insertMany(DemoQuery query) {
    final list = (query.payload as List).cast<Map<String, dynamic>>();
    final inserted = <Map<String, dynamic>>[];
    for (final raw in list) {
      final data = Map<String, dynamic>.from(raw);
      if (!data.containsKey('id')) data['id'] = _id();
      table(query.table).add(data);
      inserted.add(data);
    }
    return _finalizeSelect(inserted, query);
  }

  dynamic _update(DemoQuery query) {
    final rows = table(query.table);
    final patch = Map<String, dynamic>.from(query.payload as Map);
    final updated = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (_matchesFilters(row, query.filters)) {
        row.addAll(patch);
        updated.add(row);
      }
    }
    return _finalizeSelect(updated, query);
  }

  dynamic _upsert(DemoQuery query) {
    final payload = query.payload;
    if (payload is List) {
      for (final raw in payload) {
        _upsertOne(query.table, Map<String, dynamic>.from(raw as Map));
      }
      return null;
    }
    return _upsertOne(query.table, Map<String, dynamic>.from(payload as Map));
  }

  Map<String, dynamic> _upsertOne(String tableName, Map<String, dynamic> data) {
    final rows = table(tableName);
    final key = data['id'] ?? data['user_id'];
    final idx = rows.indexWhere((r) {
      if (data['id'] != null && r['id'] == data['id']) return true;
      if (tableName == 'my_agenda' &&
          r['user_id'] == data['user_id'] &&
          r['session_id'] == data['session_id']) {
        return true;
      }
      if (tableName == 'profiles' && r['id'] == data['id']) return true;
      if (tableName == 'announcement_reads' &&
          r['user_id'] == data['user_id'] &&
          r['announcement_id'] == data['announcement_id']) {
        return true;
      }
      if (tableName == 'transport_boardings' &&
          r['run_id'] == data['run_id'] &&
          r['user_id'] == data['user_id']) {
        return true;
      }
      if (tableName == 'transport_settings' && r['id'] == data['id']) {
        return true;
      }
      return false;
    });
    if (idx >= 0) {
      rows[idx].addAll(data);
      return rows[idx];
    }
    if (!data.containsKey('id') && key != null) data['id'] = _id();
    rows.add(data);
    return data;
  }

  dynamic _select(DemoQuery query) {
    var rows = table(query.table).map((r) => Map<String, dynamic>.from(r)).toList();
    rows = rows.where((r) => _matchesFilters(r, query.filters)).toList();
    rows = _applyOrFilter(rows, query.orFilter);
    rows = _attachJoins(rows, query.select, query.table);
    rows = _projectColumns(rows, query.select);
    rows = _sortRows(rows, query.orderCol, query.orderAsc);
    if (query.limit != null && rows.length > query.limit!) {
      rows = rows.sublist(0, query.limit!);
    }
    return _finalizeSelect(rows, query);
  }

  dynamic _finalizeSelect(List<Map<String, dynamic>> rows, DemoQuery query) {
    if (query.single) {
      if (rows.isEmpty) throw StateError('No rows');
      return rows.first;
    }
    if (query.maybeSingle) return rows.isEmpty ? null : rows.first;
    return rows;
  }

  bool _matchesFilters(Map<String, dynamic> row, List<DemoFilter> filters) {
    for (final f in filters) {
      final val = row[f.column];
      switch (f.op) {
        case DemoFilterOp.eq:
          if (val != f.value) return false;
        case DemoFilterOp.gte:
          if (_compare(val, f.value) < 0) return false;
        case DemoFilterOp.inList:
          if (!(f.value as List).contains(val)) return false;
      }
    }
    return true;
  }

  int _compare(dynamic a, dynamic b) {
    if (a == null || b == null) return -1;
    final sa = a.toString();
    final sb = b.toString();
    return sa.compareTo(sb);
  }

  List<Map<String, dynamic>> _applyOrFilter(
    List<Map<String, dynamic>> rows,
    String? orFilter,
  ) {
    if (orFilter == null) return rows;
    // direct_messages: and(sender_id.eq.X,recipient_id.eq.Y)
    final parts = orFilter.split('),and(');
    return rows.where((row) {
      for (final part in parts) {
        final clean = part.replaceAll('and(', '').replaceAll(')', '');
        final clauses = clean.split(',');
        String? sender;
        String? recipient;
        for (final clause in clauses) {
          final bits = clause.split('.');
          if (bits.length == 3) {
            final col = bits[0];
            final op = bits[1];
            final val = bits[2];
            if (op == 'eq') {
              if (col == 'sender_id') sender = val;
              if (col == 'recipient_id') recipient = val;
            }
          }
        }
        if (sender != null &&
            recipient != null &&
            row['sender_id'] == sender &&
            row['recipient_id'] == recipient) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  List<Map<String, dynamic>> _attachJoins(
    List<Map<String, dynamic>> rows,
    String select,
    String tableName,
  ) {
    if (!select.contains('(')) return rows;

    if (tableName == 'sessions' && select.contains('session_speakers')) {
      return rows.map((session) {
        final links = table('session_speakers')
            .where((l) => l['session_id'] == session['id'])
            .toList();
        final nested = links.map((l) {
          final sp = table('speakers').firstWhere(
            (s) => s['id'] == l['speaker_id'],
            orElse: () => <String, dynamic>{},
          );
          if (select.contains('speakers(*)')) {
            return {'speakers': Map<String, dynamic>.from(sp)};
          }
          return {
            'speakers': {
              'id': sp['id'],
              'name': sp['name'],
              'avatar_url': sp['avatar_url'],
            },
          };
        }).toList();
        return {...session, 'session_speakers': nested};
      }).toList();
    }

    if (tableName == 'speakers' && select.contains('session_speakers')) {
      return rows.map((speaker) {
        final links = table('session_speakers')
            .where((l) => l['speaker_id'] == speaker['id'])
            .toList();
        final nested = links.map((l) {
          final sess = table('sessions').firstWhere(
            (s) => s['id'] == l['session_id'],
            orElse: () => <String, dynamic>{},
          );
          return {'sessions': Map<String, dynamic>.from(sess)};
        }).toList();
        return {...speaker, 'session_speakers': nested};
      }).toList();
    }

    if (tableName == 'chat_messages' && select.contains('profiles')) {
      return rows.map((msg) {
        final profile = table('profiles').firstWhere(
          (p) => p['id'] == msg['user_id'],
          orElse: () => {'display_name': 'Delegate'},
        );
        return {
          ...msg,
          'profiles': {'display_name': profile['display_name']},
        };
      }).toList();
    }

    return rows;
  }

  List<Map<String, dynamic>> _projectColumns(
    List<Map<String, dynamic>> rows,
    String select,
  ) {
    if (select == '*' || select.contains('(')) return rows;
    final cols = select.split(',').map((c) => c.trim()).toList();
    return rows
        .map((row) => {for (final c in cols) if (row.containsKey(c)) c: row[c]})
        .toList();
  }

  List<Map<String, dynamic>> _sortRows(
    List<Map<String, dynamic>> rows,
    String? col,
    bool asc,
  ) {
    if (col == null) return rows;
    final sorted = [...rows];
    sorted.sort((a, b) {
      final cmp = _compare(a[col], b[col]);
      return asc ? cmp : -cmp;
    });
    return sorted;
  }

  List<Map<String, dynamic>> rpcRedeemCode(String code) {
    final upper = code.trim().toUpperCase();
    if (upper.contains('KITCHEN')) return [{'label': 'Kitchen staff'}];
    if (upper.contains('USHER') || upper.contains('DESK')) return [{'label': 'Front desk'}];
    if (upper.contains('ADMIN')) return [{'label': 'Conference admin'}];
    return [{'label': 'Staff access'}];
  }
}

enum DemoMutation { none, insert, insertMany, update, upsert, delete }

enum DemoFilterOp { eq, gte, inList }

class DemoFilter {
  DemoFilter(this.column, this.value, this.op);
  final String column;
  final Object value;
  final DemoFilterOp op;
}

class DemoQuery {
  DemoQuery({
    required this.table,
    this.select = '*',
    this.filters = const [],
    this.orderCol,
    this.orderAsc = true,
    this.limit,
    this.maybeSingle = false,
    this.single = false,
    this.mutation = DemoMutation.none,
    this.payload,
    this.orFilter,
  });

  final String table;
  final String select;
  final List<DemoFilter> filters;
  final String? orderCol;
  final bool orderAsc;
  final int? limit;
  final bool maybeSingle;
  final bool single;
  final DemoMutation mutation;
  final Object? payload;
  final String? orFilter;

  DemoQuery copyWith({
    String? select,
    List<DemoFilter>? filters,
    String? orderCol,
    bool? orderAsc,
    int? limit,
    bool? maybeSingle,
    bool? single,
    DemoMutation? mutation,
    Object? payload,
    String? orFilter,
  }) {
    return DemoQuery(
      table: table,
      select: select ?? this.select,
      filters: filters ?? this.filters,
      orderCol: orderCol ?? this.orderCol,
      orderAsc: orderAsc ?? this.orderAsc,
      limit: limit ?? this.limit,
      maybeSingle: maybeSingle ?? this.maybeSingle,
      single: single ?? this.single,
      mutation: mutation ?? this.mutation,
      payload: payload ?? this.payload,
      orFilter: orFilter ?? this.orFilter,
    );
  }
}
