import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static String get supabaseUrl =>
      dotenv.maybeGet('SUPABASE_URL') ??
      dotenv.maybeGet('VITE_SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL');

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ??
      dotenv.maybeGet('VITE_SUPABASE_PUBLISHABLE_KEY') ??
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Demo mode uses bundled local data — any email/password works.
  /// Defaults to **on** for the conference prototype unless DEMO_MODE=false.
  static bool get isDemoMode {
    final flag = dotenv.maybeGet('DEMO_MODE')?.toLowerCase();
    if (flag == 'false' || flag == '0') return false;
    if (flag == 'true' || flag == '1') return true;
    if (!isConfigured) return true;
    // .env may include Supabase keys from the web app — still default to demo
    // so delegates can sign in without live accounts.
    return true;
  }

  /// Base URL for CPC hotel inspection photos (Hotels/public on GitHub or deployed site).
  static String get hotelsMediaBaseUrl =>
      dotenv.maybeGet('HOTELS_MEDIA_BASE_URL') ??
      'https://raw.githubusercontent.com/sagegottrill/nse/main/Hotels/public';
}
