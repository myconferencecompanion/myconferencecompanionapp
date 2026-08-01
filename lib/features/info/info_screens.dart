import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nse_mobile/config/env.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/format.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    final data = await client.from('announcements').select().order('created_at', ascending: false);
    final items = (data as List).cast<Map<String, dynamic>>();
    _markRead(items);
    return items;
  }

  /// Fire-and-forget read tracking — runs once, never inside build().
  void _markRead(List<Map<String, dynamic>> items) {
    if (_markedRead || items.isEmpty) return;
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    _markedRead = true;
    ref.read(supabaseProvider).from('announcement_reads').upsert(
          items.map((a) => {'user_id': userId, 'announcement_id': a['id']}).toList(),
        );
  }

  static const _header = NseTitleHeader(
    title: 'Announcements',
    subtitle: 'Official updates from the organisers.',
    padding: EdgeInsets.only(bottom: AppSpacing.md),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Column(children: [
              const NseTitleHeader(title: 'Announcements', subtitle: 'Official updates from the organisers.'),
              Expanded(
                child: ErrorView(
                  message: 'Could not load announcements. Check your connection.',
                  onRetry: () => setState(() => _future = _load()),
                ),
              ),
            ]);
          }
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'Announcements', subtitle: 'Official updates from the organisers.'),
              Expanded(child: LoadingView()),
            ]);
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Column(children: [
              NseTitleHeader(title: 'Announcements', subtitle: 'Official updates from the organisers.'),
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: NseEmptyState(
                  title: 'No announcements',
                  body: 'Conference updates will appear here.',
                  icon: Icons.campaign_outlined,
                ),
              ),
            ]);
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
              itemCount: items.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                if (idx == 0) return _header;
                final a = items[idx - 1];
                final high = a['priority'] == 'high';
                final posted = parseIso(a['created_at'] as String?);
                return NseCard(
                  tint: high ? AppColors.goldSoft : AppColors.surface,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NseIconBadge(
                        icon: high ? Icons.priority_high_rounded : Icons.campaign_rounded,
                        tone: high ? AppColors.goldSoft : AppColors.navySoft,
                        iconColor: high ? AppColors.gold : AppColors.navy,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sanitizeDisplay(a['title'] as String? ?? 'Update'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(sanitizeDisplay(a['body'] as String? ?? ''), style: Theme.of(context).textTheme.bodyMedium),
                            if (posted != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                formatDayLabel(posted),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  Future<void> _call(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$sanitized');
    final ok = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a call. Dial $phone manually.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: FutureBuilder(
        future: client.from('emergency_contacts').select().order('sort_order'),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Column(children: [
              NseTitleHeader(title: 'Emergency', subtitle: 'Tap a contact to call immediately.'),
              Expanded(child: ErrorView(message: 'Could not load emergency contacts.')),
            ]);
          }
          if (!snap.hasData) {
            return const Column(children: [
              NseTitleHeader(title: 'Emergency', subtitle: 'Tap a contact to call immediately.'),
              Expanded(child: LoadingView()),
            ]);
          }
          final contacts = (snap.data as List).cast<Map<String, dynamic>>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
            children: [
              const NseTitleHeader(
                title: 'Emergency',
                subtitle: 'Tap a contact to call immediately.',
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              NseCard(
                tint: AppColors.destructiveSoft,
                child: Row(
                  children: [
                    const NseIconBadge(
                      icon: Icons.health_and_safety_rounded,
                      tone: AppColors.destructiveSoft,
                      iconColor: AppColors.destructive,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap any contact to call immediately. Stay calm and follow venue staff instructions.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (contacts.isEmpty)
                const NseEmptyState(
                  title: 'No contacts listed yet',
                  body: 'Emergency numbers will appear here once published by the organisers.',
                  icon: Icons.phone_disabled_rounded,
                ),
              ...contacts.map((c) {
                final cat = (c['category'] as String?)?.toLowerCase();
                final critical = cat == 'emergency' || cat == 'medical' || cat == 'security';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NseCard(
                    onTap: () => _call(context, c['phone'] as String?),
                    tint: critical ? AppColors.destructive : AppColors.surface,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sanitizeDisplay(c['label'] as String?),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: critical ? Colors.white : AppColors.ink,
                                    ),
                              ),
                              Text(
                                sanitizeDisplay(c['phone'] as String?),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: critical ? Colors.white : AppColors.navy,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (c['description'] != null)
                                Text(
                                  sanitizeDisplay(c['description'] as String?),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: critical ? Colors.white70 : AppColors.inkSoft,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.phone_rounded, color: critical ? Colors.white : AppColors.navy),
                      ],
                    ),
                  ),
                );
              }),
              NseCard(
                tint: AppColors.cream,
                child: Text(
                  sanitizeDisplay('First-aid station next to Hall A (8am–10pm).\nConference hotline: ${EventConfig.primaryHotline}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _bio = TextEditingController();
  final _avatar = TextEditingController();
  bool _networking = true;
  bool _loading = true;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _company.dispose();
    _bio.dispose();
    _avatar.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    final profile = await ref.read(backendProvider).from('profiles').select().eq('id', userId).maybeSingle();
    if (profile != null && mounted) {
      _name.text = sanitizeDisplay(profile['display_name'] as String? ?? '');
      _title.text = sanitizeDisplay(profile['title'] as String? ?? '');
      _company.text = sanitizeDisplay(profile['company'] as String? ?? '');
      _bio.text = sanitizeDisplay(profile['bio'] as String? ?? '');
      _avatar.text = sanitizeDisplay(profile['avatar_url'] as String? ?? '');
      _networking = profile['networking_opt_in'] as bool? ?? true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _pickPhoto() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 82,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (Env.isDemoMode) {
        // In demo mode, store as base64 data URL so photo persists in profile
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64';
        if (!mounted) return;
        setState(() {
          _avatar.text = dataUrl;
          _uploading = false;
        });
        await _save();
      } else {
        // In live mode, upload to Supabase storage
        final path = '$userId/avatar.jpg';
        final storage = Supabase.instance.client.storage.from('avatars');
        await storage.uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        final url = '${storage.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
        if (!mounted) return;
        setState(() {
          _avatar.text = url;
          _uploading = false;
        });
        await _save();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload photo. $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    await ref.read(backendProvider).from('profiles').upsert({
      'id': userId,
      'display_name': _name.text.trim(),
      'title': _title.text.trim(),
      'company': _company.text.trim(),
      'bio': _bio.text.trim(),
      'avatar_url': _avatar.text.trim(),
      'networking_opt_in': _networking,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 40),
        children: [
          const NseTitleHeader(
            title: 'Your profile',
            subtitle: 'How other delegates see you.',
            padding: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          NseCard(
            tint: AppColors.cream,
                child: Row(
              children: [
                GestureDetector(
                  onTap: _uploading ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      NseAvatar(name: sanitizeDisplay(_name.text), imageUrl: sanitizeDisplay(_avatar.text), radius: 32),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 2),
                          ),
                          child: _uploading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sanitizeDisplay(_name.text).isEmpty ? 'Your name' : sanitizeDisplay(_name.text),
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sanitizeDisplay([_title.text, _company.text].where((s) => s.trim().isNotEmpty).join(' · ')),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _uploading ? null : _pickPhoto,
                        child: Text(
                          _uploading ? 'Uploading…' : 'Tap to change photo',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const NseSectionTitle(title: 'About you'),
          _ProfileField(
            label: 'Display name',
            hint: 'e.g. Amina Bello',
            icon: Icons.badge_rounded,
            controller: _name,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Title',
            hint: 'e.g. Structural Engineer',
            icon: Icons.work_rounded,
            controller: _title,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Company',
            hint: 'e.g. NSE Borno Branch',
            icon: Icons.apartment_rounded,
            controller: _company,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Bio',
            hint: 'A short line about your work and interests.',
            icon: Icons.notes_rounded,
            controller: _bio,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Photo URL',
            hint: 'https://… (optional)',
            icon: Icons.link_rounded,
            controller: _avatar,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppSpacing.lg),
          const NseSectionTitle(title: 'Visibility'),
          NseCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Visible in networking directory',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: const Text('Other delegates can find and message you'),
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.navy,
              value: _networking,
              onChanged: (v) => setState(() => _networking = v),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}

/// A labelled, borderless white input that floats on the page — matches the
/// clean form language of the reference apps.
class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
            color: AppColors.surface,
            boxShadow: AppShadows.card,
          ),
          child: TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.surface,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: multiline ? 16 : 18,
              ),
              prefixIcon: multiline
                  ? null
                  : Icon(icon, size: 20, color: AppColors.inkSoft),
            ),
          ),
        ),
      ],
    );
  }
}
