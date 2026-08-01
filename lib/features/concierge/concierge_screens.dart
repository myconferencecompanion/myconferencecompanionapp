import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/core/food_menu_cart.dart';
import 'package:nse_mobile/core/refresh_signals.dart';
import 'package:nse_mobile/core/db_query.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class UsherScreen extends ConsumerStatefulWidget {
  const UsherScreen({super.key});

  @override
  ConsumerState<UsherScreen> createState() => _UsherScreenState();
}

class _UsherScreenState extends ConsumerState<UsherScreen> {
  String _reason = 'assistance';
  final _note = TextEditingController();
  final _location = TextEditingController(text: 'Main Lobby');

  @override
  void dispose() {
    _note.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    await ref.read(supabaseProvider).from('usher_requests').insert({
      'user_id': userId,
      'reason': _reason,
      'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
      'location_label': _location.text.trim(),
    });
    if (mounted) {
      bumpActivity(ref);
      _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Usher notified'),
          action: SnackBarAction(label: 'Activity', onPressed: () => context.go('/waitlist')),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).userId;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
        children: [
          const NseTitleHeader(
            title: 'Call an usher',
            subtitle: 'A team member will come to you inside the venue.',
            padding: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          NseCard(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  items: const [
                    DropdownMenuItem(value: 'assistance', child: Text('General assistance')),
                    DropdownMenuItem(value: 'accessibility', child: Text('Accessibility')),
                    DropdownMenuItem(value: 'lost_item', child: Text('Lost item')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _reason = v ?? 'assistance'),
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: _location, decoration: const InputDecoration(labelText: 'Your location')),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)'), maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Request usher'),
          ),
          if (userId != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const NseSectionTitle(title: 'Recent requests'),
            FutureBuilder(
              future: ref.read(supabaseProvider)
                  .from('usher_requests')
                  .select()
                  .eq('user_id', userId)
                  .order('created_at', ascending: false)
                  .limit(10),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final rows = snap.data as List;
                if (rows.isEmpty) return const NseEmptyState(title: 'No requests yet', body: 'Your usher history appears here.');
                return Column(
                  children: rows.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NseCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sanitizeDisplay(r['reason'] as String?), style: Theme.of(context).textTheme.titleSmall),
                                Text(sanitizeDisplay(r['location_label'] as String?), style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          NseStatusChip(label: sanitizeDisplay(r['status'] as String?)),
                        ],
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  final Map<String, int> _cart = {};
  final _pickup = TextEditingController(text: 'ICC Catering Point B');
  final _notes = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _pickup.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _adjustCart({
    required String itemId,
    required String? categoryId,
    required int delta,
    required int itemMax,
    required Map<String, Map<String, dynamic>> itemMap,
  }) {
    final updated = FoodMenuCart.applyBump(
      cart: _cart,
      itemId: itemId,
      delta: delta,
      categoryId: categoryId,
      itemMax: itemMax,
      itemMap: itemMap,
    );
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FoodMenuCart.itemLimitMessage(itemMax))),
      );
      return;
    }
    setState(() {
      _cart
        ..clear()
        ..addAll(updated);
    });
  }

  Future<void> _place(Map<String, Map<String, dynamic>> itemMap) async {
    if (_placing) return;
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    if (_pickup.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add pickup location')));
      return;
    }
    setState(() => _placing = true);
    final client = ref.read(supabaseProvider);
    try {
      final order = await client.from('food_orders').insert({
        'user_id': userId,
        'pickup_location': _pickup.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'total_ngn': 0,
      }).select('id').single();
      final lines = _cart.entries
          .where((e) => itemMap[e.key] != null)
          .map((e) {
        final item = itemMap[e.key]!;
        return {
          'order_id': order['id'],
          'menu_item_id': e.key,
          'item_name_snapshot': item['name'],
          'quantity': e.value,
          'unit_price_ngn': 0,
        };
      }).toList();
      await client.from('food_order_items').insert(lines);
      if (!mounted) return;
      bumpActivity(ref);
      setState(() {
        _cart.clear();
        _notes.clear();
        _placing = false;
      });
      context.push('/concierge/orders');
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not place your order. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: dbWait([
          client.from('menu_categories').select().eq('is_active', true).order('sort_order'),
          client.from('menu_items').select().eq('is_available', true).order('sort_order'),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'Food menu'),
              Expanded(child: LoadingView()),
            ]);
          }
          final categories = (snap.data![0] as List).cast<Map<String, dynamic>>();
          final items = (snap.data![1] as List).cast<Map<String, dynamic>>();
          final itemMap = {for (final i in items) i['id'] as String: i};

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              const NseTitleHeader(
                title: 'Food menu',
                subtitle: 'Complimentary from the organizers — pick one per section.',
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              NseCard(
                child: Column(
                  children: [
                    TextField(controller: _pickup, decoration: const InputDecoration(labelText: 'Pickup location')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...categories.map((cat) {
                final catId = cat['id'] as String;
                final catItems = items.where((i) => i['category_id'] == catId).toList();
                if (catItems.isEmpty) return const SizedBox.shrink();
                Map<String, dynamic>? chosen;
                for (final i in catItems) {
                  if ((_cart[i['id'] as String] ?? 0) > 0) {
                    chosen = i;
                    break;
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(sanitizeDisplay(cat['name'] as String?), style: Theme.of(context).textTheme.titleSmall),
                          ),
                          NseStatusChip(
                            label: chosen != null ? '1 of 1 selected' : 'Pick one',
                            tone: chosen != null ? AppColors.greenSoft : AppColors.muted,
                            textColor: chosen != null ? AppColors.green : AppColors.inkSoft,
                          ),
                        ],
                      ),
                    ),
                    ...catItems.map((item) {
                      final id = item['id'] as String;
                      final qty = _cart[id] ?? 0;
                      final itemMax = (item['max_per_item'] as int?) ?? 1;
                      final isOtherChosen = chosen != null && chosen['id'] != id;
                      return NseMenuItemTile(
                        name: sanitizeDisplay(item['name'] as String?),
                        description: sanitizeDisplay(item['description'] as String? ?? 'Complimentary for delegates'),
                        quantity: qty,
                        itemMax: itemMax,
                        isOtherChosen: isOtherChosen,
                        canAdd: qty < itemMax,
                        onAdd: () => _adjustCart(
                          itemId: id,
                          categoryId: catId,
                          delta: 1,
                          itemMax: itemMax,
                          itemMap: itemMap,
                        ),
                        onRemove: () => _adjustCart(
                          itemId: id,
                          categoryId: catId,
                          delta: -1,
                          itemMax: itemMax,
                          itemMap: itemMap,
                        ),
                      );
                    }),
                  ],
                );
              }),
              if (_cart.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _placing ? null : () => _place(itemMap),
                  icon: _placing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_placing
                      ? 'Placing…'
                      : 'Place order (${_cart.values.fold(0, (a, b) => a + b)} items)'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ErrandsScreen extends ConsumerStatefulWidget {
  const ErrandsScreen({super.key});

  @override
  ConsumerState<ErrandsScreen> createState() => _ErrandsScreenState();
}

class _ErrandsScreenState extends ConsumerState<ErrandsScreen> {
  String _category = 'laundry';
  String _urgency = 'normal';
  final _description = TextEditingController();
  final _room = TextEditingController();
  String? _hotelId;

  @override
  void dispose() {
    _description.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    if (_description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what you need before submitting.')),
      );
      return;
    }
    await ref.read(supabaseProvider).from('errand_requests').insert({
      'user_id': userId,
      'category': _category,
      'description': _description.text.trim(),
      'accommodation_id': _hotelId,
      'room_number': _room.text.trim(),
      'urgency': _urgency,
    });
    if (mounted) {
      bumpActivity(ref);
      _description.clear();
      _room.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Errand submitted'),
          action: SnackBarAction(label: 'Activity', onPressed: () => context.go('/waitlist')),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).userId;
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: client.from('accommodations').select('id,name'),
        builder: (context, snap) {
          final hotels = snap.hasData ? (snap.data as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              const NseTitleHeader(
                title: 'Errands',
                subtitle: 'Laundry, pharmacy, transport & more — handled by the team.',
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              NseCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      items: const [
                        DropdownMenuItem(value: 'laundry', child: Text('Laundry')),
                        DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy run')),
                        DropdownMenuItem(value: 'grocery', child: Text('Grocery')),
                        DropdownMenuItem(value: 'document', child: Text('Document / print')),
                        DropdownMenuItem(value: 'transport', child: Text('Transport')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? 'laundry'),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (hotels.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: _hotelId,
                        items: hotels
                          .map((h) => DropdownMenuItem(value: h['id'] as String, child: Text(sanitizeDisplay(h['name'] as String?))))
                          .toList(),
                        onChanged: (v) => setState(() => _hotelId = v),
                        decoration: const InputDecoration(labelText: 'Hotel'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    TextField(controller: _room, decoration: const InputDecoration(labelText: 'Room number')),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _urgency,
                      items: const [
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (v) => setState(() => _urgency = v ?? 'normal'),
                      decoration: const InputDecoration(labelText: 'Urgency'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit errand'),
              ),
              if (userId != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const NseSectionTitle(title: 'Your errands'),
                FutureBuilder(
                  future: client
                      .from('errand_requests')
                      .select()
                      .eq('user_id', userId)
                      .order('created_at', ascending: false)
                      .limit(8),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox();
                    final rows = snap.data as List;
                    if (rows.isEmpty) {
                      return const NseEmptyState(title: 'No errands yet', body: 'Submitted errands appear here.');
                    }
                    return Column(
                      children: rows
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NseCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(sanitizeDisplay(r['category'] as String?), style: Theme.of(context).textTheme.titleSmall),
                                          Text(sanitizeDisplay(r['description'] as String? ?? ''), style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    NseStatusChip(label: sanitizeDisplay((r['status'] as String).replaceAll('_', ' '))),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    final client = ref.read(supabaseProvider);
    setState(() {
      _future = dbWait([
        client.from('food_orders').select().eq('user_id', userId).order('created_at', ascending: false),
        client.from('errand_requests').select().eq('user_id', userId).order('created_at', ascending: false),
        client.from('food_order_items').select(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activityRefreshProvider, (prev, next) => _reload());

    final userId = ref.watch(authProvider).userId;
    if (userId == null) return const Scaffold(body: ErrorView(message: 'Sign in required'));

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'My orders'),
              Expanded(child: LoadingView()),
            ]);
          }
          if (snap.hasError) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  const NseEmptyState(
                    title: 'Could not load orders',
                    body: 'Pull down to retry.',
                    icon: Icons.error_outline_rounded,
                  ),
                ],
              ),
            );
          }
          final food = (snap.data![0] as List).cast<Map<String, dynamic>>();
          final errands = (snap.data![1] as List).cast<Map<String, dynamic>>();
          final allItems = (snap.data![2] as List).cast<Map<String, dynamic>>();

          if (food.isEmpty && errands.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  NseEmptyState(
                    title: 'No orders yet',
                    body: 'Food and errand requests you place through Concierge will appear here.',
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
              children: [
                const NseTitleHeader(
                  title: 'My orders',
                  subtitle: 'Food and errand requests you placed.',
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                ),
                if (food.isNotEmpty) ...[
                  const NseSectionTitle(title: 'Food orders'),
                  ...food.map((o) {
                    final lines = allItems.where((i) => i['order_id'] == o['id']).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NseCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    o['pickup_location'] as String? ?? 'Food order',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                NseStatusChip(label: (o['status'] as String).replaceAll('_', ' ')),
                              ],
                            ),
                            if (o['notes'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(sanitizeDisplay(o['notes'] as String?), style: Theme.of(context).textTheme.bodySmall),
                              ),
                            if (lines.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...lines.map(
                                (l) => Text(
                                  '· ${l['quantity']}× ${sanitizeDisplay(l['item_name_snapshot'] as String?)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (errands.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const NseSectionTitle(title: 'Errands'),
                  ...errands.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NseCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sanitizeDisplay(e['category'] as String?), style: Theme.of(context).textTheme.titleSmall),
                                  Text(sanitizeDisplay(e['description'] as String? ?? ''), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            NseStatusChip(label: sanitizeDisplay((e['status'] as String).replaceAll('_', ' '))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
