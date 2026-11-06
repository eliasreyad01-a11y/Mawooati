/// دوال تحقق نقية (ترجع رسالة الخطأ أو null عند الصحة).
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'أدخل البريد الإلكتروني';
    if (!_email.hasMatch(s)) return 'البريد الإلكتروني غير صالح';
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'أدخل كلمة المرور';
    if (s.length < 8) return 'كلمة المرور 8 أحرف على الأقل';
    if (!RegExp(r'[A-Za-z\u0621-\u064A]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'يجب أن تحتوي على حروف وأرقام';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) =>
      v == original ? null : 'كلمتا المرور غير متطابقتين';

  static String? required(String? v, String message, {int max = 80}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return message;
    if (s.length > max) return 'الحد الأقصى $max حرفاً';
    return null;
  }
}
