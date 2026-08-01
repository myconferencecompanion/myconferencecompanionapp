import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_mobile/core/admin_config.dart';
import 'package:nse_mobile/config/env.dart';
import 'package:nse_mobile/data/demo/demo_backend.dart';
import 'package:nse_mobile/data/demo/demo_ids.dart';
import 'package:nse_mobile/data/demo/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AppRole = String;

const pendingCodeKey = 'pending_role_code';

final demoBackendProvider = Provider<DemoBackend>((ref) {
  return DemoBackend(DemoStore.instance);
});

final liveBackendProvider = Provider<LiveBackend>((ref) {
  return LiveBackend(Supabase.instance.client);
});

/// Conference data + realtime — demo or live Supabase.
final backendProvider = Provider<dynamic>((ref) {
  if (Env.isDemoMode) return ref.watch(demoBackendProvider);
  return ref.watch(liveBackendProvider);
});

@Deprecated('Use backendProvider')
final supabaseProvider = backendProvider;

class AuthState {
  const AuthState({
    this.session,
    this.roles = const [],
    this.loading = true,
    this.isDemo = false,
    this.demoUserId,
    this.demoFullName,
  });

  final Session? session;
  final List<AppRole> roles;
  final bool loading;
  final bool isDemo;
  final String? demoUserId;
  final String? demoFullName;

  User? get user => session?.user;
  String? get userId => user?.id ?? demoUserId;
  String get displayName =>
      user?.userMetadata?['full_name'] as String? ?? demoFullName ?? 'Delegate';

  bool get isLoggedIn => user != null || demoUserId != null;
  bool get isAdmin => roles.contains('admin') || roles.contains('super_admin');

  bool get canAccessAdmin => canAccessAdminConsole(roles);

  bool hasRole(AppRole role) => roles.contains(role);

  bool hasAnyAdminRole(List<AppRole> required) =>
      roles.contains('super_admin') ||
      required.any((role) => roles.contains(role));

  AuthState copyWith({
    Session? session,
    List<AppRole>? roles,
    bool? loading,
    bool? isDemo,
    String? demoUserId,
    String? demoFullName,
    bool clearDemo = false,
  }) {
    return AuthState(
      session: session ?? this.session,
      roles: roles ?? this.roles,
      loading: loading ?? this.loading,
      isDemo: clearDemo ? false : (isDemo ?? this.isDemo),
      demoUserId: clearDemo ? null : (demoUserId ?? this.demoUserId),
      demoFullName: clearDemo ? null : (demoFullName ?? this.demoFullName),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    if (Env.isDemoMode) {
      Future.microtask(_initDemo);
      return const AuthState(loading: true);
    }

    final client = Supabase.instance.client;
    Future.microtask(_initLive);
    client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session?.user != null) {
        if (data.event == AuthChangeEvent.signedIn) {
          await _redeemPendingCode();
        }
        final roles = await _loadRoles(session!.user.id);
        state = AuthState(session: session, roles: roles, loading: false);
      } else {
        state = const AuthState(loading: false);
      }
    });
    return const AuthState(loading: true);
  }

  Future<void> _initDemo() async {
    await DemoStore.instance.init();
    state = const AuthState(loading: false);
  }

  AuthState _prototypeSession({
    required String email,
    String? fullName,
    bool asAdmin = false,
  }) {
    final name = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : _nameFromEmail(email);
    final roles = asAdmin
        ? ['admin', 'super_admin', 'program', 'logistics', 'comms', 'kitchen', 'front_desk']
        : ['attendee'];
    return AuthState(
      isDemo: true,
      demoUserId: asAdmin ? DemoIds.admin : DemoIds.delegate,
      demoFullName: name,
      roles: roles,
      loading: false,
    );
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Delegate';

    final normalized = local
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(RegExp(r'([A-Z]+)([A-Z][a-z])'), (m) => '${m[1]} ${m[2]}');

    final parts = normalized
        .split(RegExp(r'[._\-\d]+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return parts
          .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
          .join(' ');
    }

    final word = parts.isEmpty ? local : parts.first;
    if (word.length <= 1) return word.toUpperCase();
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  Future<void> _initLive() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session?.user != null) {
      final roles = await _loadRoles(session!.user.id);
      state = AuthState(session: session, roles: roles, loading: false);
    } else {
      state = const AuthState(loading: false);
    }
  }

  Future<List<AppRole>> _loadRoles(String userId) async {
    final client = Supabase.instance.client;
    final res = await client.from('user_roles').select('role').eq('user_id', userId);
    return (res as List).map((r) => r['role'] as String).toList();
  }

  Future<void> stashPendingRoleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingCodeKey, code.trim());
  }

  Future<void> _redeemPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(pendingCodeKey);
    if (code == null || code.isEmpty) return;
    await prefs.remove(pendingCodeKey);
    final client = Supabase.instance.client;
    await client.rpc('redeem_signup_code', params: {'_code': code});
  }

  Future<void> _ensureDemoProfile(String userId, String displayName) async {
    final profiles = DemoStore.instance.table('profiles');
    final idx = profiles.indexWhere((p) => p['id'] == userId);
    final row = {
      'id': userId,
      'display_name': displayName,
      'title': 'Conference delegate',
      'company': 'NSE Branch',
      'bio': '',
      'avatar_url': null,
      'networking_opt_in': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (idx >= 0) {
      profiles[idx]['display_name'] = displayName;
    } else {
      profiles.add(row);
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
    String? roleCode,
  }) async {
    try {
      if (Env.isDemoMode) {
        await DemoStore.instance.init();
        final asAdmin = email.toLowerCase().contains('admin');
        state = _prototypeSession(email: email, asAdmin: asAdmin);
        await _ensureDemoProfile(
          state.demoUserId!,
          state.displayName,
        );
        if (roleCode != null && roleCode.trim().isNotEmpty) {
          await redeemCode(roleCode);
        }
        return null;
      }
      if (roleCode != null && roleCode.trim().isNotEmpty) {
        await stashPendingRoleCode(roleCode);
      }
      final client = Supabase.instance.client;
      final res = await client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      return res.user == null ? 'Sign in failed' : null;
    } on TimeoutException {
      return 'Connection timed out. Try again or enable demo mode.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Sign in failed. Please try again.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? roleCode,
  }) async {
    try {
      if (Env.isDemoMode) {
        await DemoStore.instance.init();
        state = _prototypeSession(
          email: email,
          fullName: fullName,
          asAdmin: email.toLowerCase().contains('admin'),
        );
        await _ensureDemoProfile(state.demoUserId!, state.displayName);
        if (roleCode != null && roleCode.trim().isNotEmpty) {
          await redeemCode(roleCode);
        }
        return null;
      }
      if (roleCode != null && roleCode.trim().isNotEmpty) {
        await stashPendingRoleCode(roleCode);
      }
      final client = Supabase.instance.client;
      final res = await client.auth
          .signUp(
            email: email,
            password: password,
            data: {'full_name': fullName},
          )
          .timeout(const Duration(seconds: 20));
      return res.user == null ? 'Sign up failed' : null;
    } on TimeoutException {
      return 'Connection timed out. Try again or enable demo mode.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Sign up failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    if (Env.isDemoMode) {
      state = const AuthState(loading: false);
      return;
    }
    await Supabase.instance.client.auth.signOut();
    state = const AuthState(loading: false);
  }

  /// Sends a password-reset email. Returns null on success, or an error message.
  Future<String?> resetPassword(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Enter your email first';
    if (Env.isDemoMode) {
      return 'Password reset is available once connected to the live server.';
    }
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(trimmed)
          .timeout(const Duration(seconds: 20));
      return null;
    } on TimeoutException {
      return 'Connection timed out. Please try again.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not send reset email. Please try again.';
    }
  }

  Future<void> refreshRoles() async {
    final user = state.user;
    if (user == null) return;
    final roles = await _loadRoles(user.id);
    state = state.copyWith(roles: roles);
  }

  Future<String?> redeemCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;

    if (Env.isDemoMode) {
      final roles = {...state.roles};
      final upper = trimmed.toUpperCase();
      if (upper.contains('ADMIN') || upper.contains('SUPER')) {
        roles.add('admin');
        roles.add('super_admin');
        roles.addAll(['program', 'logistics', 'comms', 'kitchen', 'front_desk']);
      } else if (upper.contains('KITCHEN') || upper.contains('CATER')) {
        roles.add('admin');
        roles.add('kitchen');
      } else if (upper.contains('PROGRAM') || upper.contains('SPEAKER')) {
        roles.add('admin');
        roles.add('program');
      } else if (upper.contains('USHER') || upper.contains('DESK') || upper.contains('SECURITY')) {
        roles.add('admin');
        roles.add('front_desk');
      } else if (upper.contains('LOGISTIC') || upper.contains('HOTEL')) {
        roles.add('admin');
        roles.add('logistics');
      } else if (upper.contains('COMM') || upper.contains('ANNOUNCE')) {
        roles.add('admin');
        roles.add('comms');
      } else {
        roles.add('attendee');
      }
      state = state.copyWith(roles: roles.toList());
      return 'Role granted';
    }

    final client = Supabase.instance.client;
    final res = await client.rpc('redeem_signup_code', params: {'_code': trimmed});
    await refreshRoles();
    if (res is List && res.isNotEmpty) {
      return res.first['label'] as String?;
    }
    return null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
