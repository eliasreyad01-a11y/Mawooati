import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  bool get isSignedIn;
  String? get email;
  Stream<void> get changes;
  Future<void> signIn(String email, String password);

  /// يرجع true إن كان يجب تأكيد البريد قبل الدخول.
  Future<bool> signUp(String email, String password, String displayName);
  Future<void> resetPassword(String email);
  Future<void> signOut();
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => SupabaseAuthRepository());

class SupabaseAuthRepository implements AuthRepository {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Stream<void> get changes => _auth.onAuthStateChange.map((_) {});

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthException catch (e) {
      throw AppException(_arabic(e));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
          'تعذّر الاتصال. تحقق من الإنترنت وحاول مجدداً.\n(${e.runtimeType}: $e)');
    }
  }

  static String _arabic(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'email_not_confirmed':
        return 'يرجى تأكيد بريدك الإلكتروني أولاً من الرسالة التي وصلتك.';
      case 'user_already_exists':
      case 'email_exists':
        return 'هذا البريد مسجّل مسبقاً. جرّب تسجيل الدخول.';
      case 'weak_password':
        return 'كلمة المرور ضعيفة. اختر كلمة أقوى.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';
      default:
        final detail = [e.statusCode, e.code, e.message]
            .where((x) => x != null && x.toString().isNotEmpty)
            .join(' | ');
        return 'تعذّر إتمام العملية. حاول مجدداً.\n($detail)';
    }
  }

  @override
  Future<void> signIn(String email, String password) => _guard(() async {
        await _auth.signInWithPassword(email: email.trim(), password: password);
      });

  @override
  Future<bool> signUp(String email, String password, String displayName) =>
      _guard(() async {
        final res = await _auth.signUp(
          email: email.trim(),
          password: password,
          data: {'display_name': displayName.trim()},
        );
        return res.session == null;
      });

  @override
  Future<void> resetPassword(String email) =>
      _guard(() => _auth.resetPasswordForEmail(email.trim()));

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());
}
