import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/config/env.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: NseTitleHeader(
              title: 'Networking',
              subtitle: 'Meet delegates and join the conversation.',
              onBack: () => context.pop(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Chat rooms'), Tab(text: 'People')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
          FutureBuilder(
            future: client.from('chat_rooms').select().order('sort_order'),
            builder: (context, snap) {
              if (!snap.hasData) return const LoadingView();
              final rooms = (snap.data as List).cast<Map<String, dynamic>>();
              if (rooms.isEmpty) {
                return const NseEmptyState(
                  title: 'No chat rooms',
                  body: 'Public conference rooms will appear here.',
                  icon: Icons.forum_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: rooms.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = rooms[i];
                  return NseCard(
                    onTap: () => context.push('/network/room/${r['id']}'),
                    child: NseListRow(
                      icon: Icons.forum_rounded,
                      title: r['name'] as String,
                      subtitle: r['description'] as String? ?? 'Join the conversation',
                      onTap: () => context.push('/network/room/${r['id']}'),
                    ),
                  );
                },
              );
            },
          ),
          FutureBuilder(
            future: client.from('profiles').select().eq('networking_opt_in', true).order('display_name'),
            builder: (context, snap) {
              if (!snap.hasData) return const LoadingView();
              final people = (snap.data as List).cast<Map<String, dynamic>>();
              final q = _search.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? people
                  : people.where((p) {
                      final hay = '${p['display_name']} ${p['company']} ${p['title']}'.toLowerCase();
                      return hay.contains(q);
                    }).toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'Search delegates',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const NseEmptyState(
                            title: 'No matches',
                            body: 'Try another name, company, or title.',
                            icon: Icons.person_search_rounded,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              return NseCard(
                                onTap: () => context.push('/network/user/${p['id']}'),
                                child: Row(
                                  children: [
                                    NseAvatar(
                                      name: p['display_name'] as String?,
                                      imageUrl: p['avatar_url'] as String?,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['display_name'] as String? ?? 'Delegate',
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          Text(
                                            '${p['title'] ?? ''} ${p['company'] ?? ''}'.trim(),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.navy),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomChatScreen extends ConsumerStatefulWidget {
  const RoomChatScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends ConsumerState<RoomChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _roomName;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    final room = await ref.read(supabaseProvider)
        .from('chat_rooms')
        .select('name')
        .eq('id', widget.roomId)
        .maybeSingle();
    if (mounted && room != null) setState(() => _roomName = room['name'] as String?);
  }

  Future<void> _load() async {
    final data = await ref.read(supabaseProvider)
        .from('chat_messages')
        .select('*, profiles(display_name)')
        .eq('room_id', widget.roomId)
        .order('created_at');
    if (!mounted) return;
    setState(() => _messages = (data as List).cast<Map<String, dynamic>>());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadMeta();
      await _load();
    });
    if (Env.isDemoMode) {
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
    } else {
      ref.read(backendProvider).channel('room-${widget.roomId}').onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: widget.roomId),
        callback: (_) => _load(),
      ).subscribe();
    }
  }

  Future<void> _send() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null || _input.text.trim().isEmpty) return;
    await ref.read(backendProvider).from('chat_messages').insert({
      'room_id': widget.roomId,
      'user_id': userId,
      'content': _input.text.trim(),
    });
    _input.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_roomName ?? 'Room chat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: NseEmptyState(
                        title: 'Start the conversation',
                        body: 'Say hello to delegates in ${_roomName ?? 'this room'}.',
                        icon: Icons.chat_outlined,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final profile = m['profiles'] as Map<String, dynamic>?;
                      final mine = m['user_id'] == ref.watch(authProvider).userId;
                      return NseChatBubble(
                        text: m['content'] as String,
                        mine: mine,
                        author: mine ? null : profile?['display_name'] as String?,
                      );
                    },
                  ),
          ),
          NseChatComposer(controller: _input, onSend: _send, hint: 'Message the room'),
        ],
      ),
    );
  }
}

class DmScreen extends ConsumerStatefulWidget {
  const DmScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends ConsumerState<DmScreen> {
  final _input = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String? _peerName;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    final profile = await ref.read(supabaseProvider)
        .from('profiles')
        .select('display_name')
        .eq('id', widget.userId)
        .maybeSingle();
    if (mounted && profile != null) {
      setState(() => _peerName = profile['display_name'] as String?);
    }
  }

  Future<void> _load() async {
    final me = ref.read(authProvider).userId;
    if (me == null) return;
    final data = await ref.read(supabaseProvider)
        .from('direct_messages')
        .select()
        .or('and(sender_id.eq.$me,recipient_id.eq.${widget.userId}),and(sender_id.eq.${widget.userId},recipient_id.eq.$me)')
        .order('created_at');
    if (mounted) setState(() => _messages = (data as List).cast<Map<String, dynamic>>());
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadMeta();
      await _load();
    });
  }

  Future<void> _send() async {
    final me = ref.read(authProvider).userId;
    if (me == null || _input.text.trim().isEmpty) return;
    await ref.read(backendProvider).from('direct_messages').insert({
      'sender_id': me,
      'recipient_id': widget.userId,
      'content': _input.text.trim(),
    });
    _input.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).userId;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_peerName ?? 'Direct message', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const NseEmptyState(
                    title: 'Start a conversation',
                    body: 'Send a message to connect with this delegate.',
                    icon: Icons.chat_bubble_outline_rounded,
                  )
                : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return NseChatBubble(
                  text: m['content'] as String,
                  mine: m['sender_id'] == me,
                );
              },
            ),
          ),
          NseChatComposer(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}
