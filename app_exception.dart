/// خطأ مفهوم للمستخدم برسالة عربية جاهزة للعرض.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
