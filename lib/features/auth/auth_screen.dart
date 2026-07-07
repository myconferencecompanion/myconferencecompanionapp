import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nse_mobile/config/env.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/core/widgets/nse_ui.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _roleCode = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && mounted) {
        setState(() => _error = null);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _roleCode.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool signUp, String? redirectTo}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    String? err;
    try {
      if (signUp) {
        err = await ref.read(authProvider.notifier).signUp(
              email: _email.text.trim(),
              password: _password.text,
              fullName: _fullName.text.trim(),
              roleCode: _roleCode.text,
            );
      } else {
        err = await ref.read(authProvider.notifier).signIn(
              email: _email.text.trim(),
              password: _password.text,
              roleCode: _roleCode.text,
            );
      }
    } catch (_) {
      err = 'Something went wrong. Please try again.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    TextInput.finishAutofillContext();

    if (signUp && !Env.isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Check your email to confirm.')),
      );
      return;
    }

    if (ref.read(authProvider).isLoggedIn) {
      context.go(redirectTo ?? '/home');
    }
  }

  Future<void> _signInAsAdmin() async {
    if (_tabs.index != 0) {
      _tabs.animateTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    _email.text = 'admin@nse.org';
    _password.text = 'demo123456';
    _roleCode.clear();
    await _submit(signUp: false, redirectTo: '/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _heroHeader(context),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        boxShadow: AppShadows.elevated,
                      ),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: AnimatedBuilder(
                            animation: _tabs,
                            builder: (context, _) => _formBody(_tabs.index == 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: AppShadows.elevated,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.heroSheen,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 44),
              child: Column(
                children: [
                  const NseBrandCoin(size: 88),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'OFFICIAL CONFERENCE APP',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    EventConfig.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${EventConfig.dates}  ·  ${EventConfig.venueAddress}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formBody(bool signUp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          signUp ? 'Create account' : 'Welcome back',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          signUp ? 'Join the conference delegate network' : 'Sign in to your delegate account',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              boxShadow: AppShadows.card,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.zero,
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.inkSoft,
            tabs: const [
              Tab(text: 'Sign in', height: 44),
              Tab(text: 'Register', height: 44),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          _errorBanner(_error!),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (signUp) ...[
          TextFormField(
            controller: _fullName,
            textInputAction: TextInputAction.next,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_busy,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return 'Enter your email';
            if (!value.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _password,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          enabled: !_busy,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: _busy ? null : () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
          validator: (v) {
            final value = v ?? '';
            if (value.isEmpty) return 'Enter your password';
            if (value.length < 6) return 'At least 6 characters';
            return null;
          },
          onFieldSubmitted: (_) => _submit(signUp: signUp),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _roleCode,
          textCapitalization: TextCapitalization.characters,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Staff role code (optional)',
            hintText: 'NSE-KITCHEN-3046',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: _busy ? null : () => _submit(signUp: signUp),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(signUp ? 'Create account' : 'Sign in'),
        ),
        if (!signUp && Env.isDemoMode) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _busy ? null : _signInAsAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: const Text('Admin demo login'),
          ),
          const SizedBox(height: 4),
          Text(
            'Opens all staff dashboards: program, catering, front desk, logistics, comms, and delegates.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.destructiveSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.destructive, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
