import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/core/widgets/page_widgets.dart';
import 'package:nse_mobile/features/admin/admin_screens.dart' show AdminGate;
import 'package:nse_mobile/theme/app_theme.dart';

enum CrudFieldType { text, multiline, number, boolean, select, datetime }

class CrudOption {
  const CrudOption(this.value, this.label);
  final String value;
  final String label;
}

class CrudField {
  const CrudField({
    required this.key,
    required this.label,
    this.type = CrudFieldType.text,
    this.required = false,
    this.hint,
    this.options,
    this.optionsTable,
    this.optionsValueKey = 'id',
    this.optionsLabelKey = 'name',
    this.defaultValue,
  });

  final String key;
  final String label;
  final CrudFieldType type;
  final bool required;
  final String? hint;
  final List<CrudOption>? options;

  /// For dynamic select fields, the table to load options from.
  final String? optionsTable;
  final String optionsValueKey;
  final String optionsLabelKey;
  final Object? defaultValue;
}

/// Generic, production-grade admin CRUD: list + add + edit + delete for a table.
class AdminCrudScreen extends ConsumerStatefulWidget {
  const AdminCrudScreen({
    super.key,
    required this.title,
    required this.itemNoun,
    required this.table,
    required this.roles,
    required this.fields,
    required this.titleKey,
    this.subtitleKeys = const [],
    this.badgeKey,
    this.orderColumn = 'created_at',
    this.orderAscending = false,
  });

  final String title;
  final String itemNoun;
  final String table;
  final List<String> roles;
  final List<CrudField> fields;
  final String titleKey;
  final List<String> subtitleKeys;
  final String? badgeKey;
  final String orderColumn;
  final bool orderAscending;

  @override
  ConsumerState<AdminCrudScreen> createState() => _AdminCrudScreenState();
}

class _AdminCrudScreenState extends ConsumerState<AdminCrudScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final Map<String, List<CrudOption>> _dynamicOptions = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    // Preload options for any dynamic select fields.
    for (final f in widget.fields) {
      if (f.optionsTable != null && !_dynamicOptions.containsKey(f.key)) {
        final rows = await client.from(f.optionsTable!).select();
        _dynamicOptions[f.key] = (rows as List)
            .cast<Map<String, dynamic>>()
            .map((r) => CrudOption(
                  '${r[f.optionsValueKey]}',
                  '${r[f.optionsLabelKey] ?? r[f.optionsValueKey]}',
                ))
            .toList();
      }
    }
    final data = await client
        .from(widget.table)
        .select()
        .order(widget.orderColumn, ascending: widget.orderAscending)
        .limit(200);
    return (data as List).cast<Map<String, dynamic>>();
  }

  void _refresh() => setState(() => _future = _load());

  List<CrudOption> _optionsFor(CrudField f) => f.options ?? _dynamicOptions[f.key] ?? const [];

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final formTitle = existing == null ? 'New ${widget.itemNoun}' : 'Edit ${widget.itemNoun}';
    final saved = await NseBottomSheet.show<bool>(
      context,
      title: formTitle,
      subtitle: 'Changes apply immediately for delegates.',
      child: _CrudForm(
        fields: widget.fields,
        optionsFor: _optionsFor,
        existing: existing,
        onSubmit: (values) async {
          final client = ref.read(supabaseProvider);
          if (existing == null) {
            await client.from(widget.table).insert(values);
          } else {
            await client.from(widget.table).update(values).eq('id', existing['id']);
          }
        },
      ),
    );
    if (saved == true) {
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.itemNoun} saved')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final ok = await NseConfirmDialog.show(
      context,
      title: 'Delete ${widget.itemNoun}?',
      message: '“${row[widget.titleKey] ?? widget.itemNoun}” will be permanently removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(supabaseProvider).from(widget.table).delete().eq('id', row['id']);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.itemNoun} deleted')),
      );
    }
  }

  String _subtitleFor(Map<String, dynamic> row) {
    return widget.subtitleKeys
        .map((k) => row[k])
        .where((v) => v != null && '$v'.trim().isNotEmpty)
        .map((v) => '$v')
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AdminGate(
      requiredRoles: widget.roles,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_rounded),
          label: Text('Add ${widget.itemNoun}'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: NseTitleHeader(
                title: widget.title,
                subtitle: 'Manage ${widget.itemNoun}s for the conference.',
                onBack: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snap) {
            if (snap.hasError) {
              return ErrorView(message: '${snap.error}', onRetry: _refresh);
            }
            if (!snap.hasData) return const LoadingView();
            final rows = snap.data!;
            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: NseEmptyState(
                  title: 'No ${widget.itemNoun}s yet',
                  body: 'Tap “Add ${widget.itemNoun}” to create the first one.',
                  icon: Icons.playlist_add_rounded,
                  action: FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add ${widget.itemNoun}'),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = rows[i];
                final subtitle = _subtitleFor(r);
                final badge = widget.badgeKey == null ? null : r[widget.badgeKey!];
                return NseCard(
                  onTap: () => _openForm(existing: r),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${r[widget.titleKey] ?? '(untitled)'}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (badge != null && '$badge'.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  NseStatusChip(label: '$badge'.replaceAll('_', ' ')),
                                ],
                              ],
                            ),
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkSoft),
                        onSelected: (v) {
                          if (v == 'edit') _openForm(existing: r);
                          if (v == 'delete') _confirmDelete(r);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrudForm extends StatefulWidget {
  const _CrudForm({
    required this.fields,
    required this.optionsFor,
    required this.existing,
    required this.onSubmit,
  });

  final List<CrudField> fields;
  final List<CrudOption> Function(CrudField) optionsFor;
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;

  @override
  State<_CrudForm> createState() => _CrudFormState();
}

class _CrudFormState extends State<_CrudForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _text = {};
  final Map<String, dynamic> _values = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final initial = widget.existing?[f.key] ?? f.defaultValue;
      switch (f.type) {
        case CrudFieldType.boolean:
          _values[f.key] = initial == true;
        case CrudFieldType.select:
          _values[f.key] = initial?.toString();
        case CrudFieldType.datetime:
          _values[f.key] = initial?.toString();
        default:
          _text[f.key] = TextEditingController(text: initial?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime(CrudField f) async {
    final current = DateTime.tryParse(_values[f.key]?.toString() ?? '')?.toLocal() ?? DateTime(2026, 11, 30, 9);
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (!mounted) return;
    final picked = DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0);
    setState(() => _values[f.key] = picked.toUtc().toIso8601String());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final payload = <String, dynamic>{};
    for (final f in widget.fields) {
      switch (f.type) {
        case CrudFieldType.boolean:
          payload[f.key] = _values[f.key] == true;
        case CrudFieldType.number:
          final raw = _text[f.key]!.text.trim();
          payload[f.key] = raw.isEmpty ? null : num.tryParse(raw);
        case CrudFieldType.select:
        case CrudFieldType.datetime:
          if (_values[f.key] != null) payload[f.key] = _values[f.key];
        default:
          final raw = _text[f.key]!.text.trim();
          if (raw.isNotEmpty || f.required) payload[f.key] = raw;
      }
    }
    try {
      await widget.onSubmit(payload);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: NseCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      for (final f in widget.fields) ...[
                        _fieldWidget(f),
                        if (f != widget.fields.last) const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldWidget(CrudField f) {
    switch (f.type) {
      case CrudFieldType.boolean:
        return NseCard(
          flat: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(f.label, style: Theme.of(context).textTheme.titleSmall),
            value: _values[f.key] == true,
            activeThumbColor: AppColors.navy,
            onChanged: (v) => setState(() => _values[f.key] = v),
          ),
        );
      case CrudFieldType.select:
        final options = widget.optionsFor(f);
        return DropdownButtonFormField<String>(
          initialValue: options.any((o) => o.value == _values[f.key]) ? _values[f.key] as String? : null,
          decoration: InputDecoration(labelText: f.label),
          items: [
            for (final o in options) DropdownMenuItem(value: o.value, child: Text(o.label)),
          ],
          validator: f.required ? (v) => (v == null || v.isEmpty) ? 'Select ${f.label}' : null : null,
          onChanged: (v) => setState(() => _values[f.key] = v),
        );
      case CrudFieldType.datetime:
        final v = _values[f.key];
        final dt = v == null ? null : DateTime.tryParse('$v')?.toLocal();
        final label = dt == null
            ? 'Pick date & time'
            : '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        return InkWell(
          onTap: () => _pickDateTime(f),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: InputDecorator(
            decoration: InputDecoration(labelText: f.label),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, size: 18, color: AppColors.inkSoft),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        );
      case CrudFieldType.number:
        return TextFormField(
          controller: _text[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: InputDecoration(labelText: f.label, hintText: f.hint),
          validator: f.required ? (v) => (v == null || v.trim().isEmpty) ? 'Enter ${f.label}' : null : null,
        );
      case CrudFieldType.multiline:
        return TextFormField(
          controller: _text[f.key],
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(labelText: f.label, hintText: f.hint, alignLabelWithHint: true),
          validator: f.required ? (v) => (v == null || v.trim().isEmpty) ? 'Enter ${f.label}' : null : null,
        );
      default:
        return TextFormField(
          controller: _text[f.key],
          decoration: InputDecoration(labelText: f.label, hintText: f.hint),
          validator: f.required ? (v) => (v == null || v.trim().isEmpty) ? 'Enter ${f.label}' : null : null,
        );
    }
  }
}
