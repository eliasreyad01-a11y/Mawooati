/// يُمرَّر عند التشغيل: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// مفتاح anon مصمَّم ليكون علنياً بشرط تفعيل RLS. لا تضع هنا مفتاح service_role أبداً.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
