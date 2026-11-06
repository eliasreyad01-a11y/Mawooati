# إعداد Supabase (مرة واحدة)

1. أنشئ حساباً مجانياً على supabase.com ثم **New project** (اختر منطقة Frankfurt).
2. من **SQL Editor** الصق محتوى `supabase/migrations/0001_core.sql` كاملاً ثم **Run**.
3. من **Authentication ← Providers ← Email**: اترك "Confirm email" مفعّلاً.
4. من **Authentication ← URL Configuration**: ضع Site URL مؤقتاً (مثلاً رابط موقعك أو `https://localhost`).
   تنبيه: رابط "إعادة تعيين كلمة المرور" يفتح صفحة ويب، وإكمال التعيين داخل التطبيق يحتاج Deep Links (المرحلة 8).
5. من **Settings ← API** انسخ **Project URL** و **anon public key**. لا تنسخ `service_role` ولا تضعه في أي مكان بالتطبيق.

## تشغيل التطبيق محلياً
```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## بناء APK على GitHub
في المستودع: **Settings ← Secrets and variables ← Actions ← New repository secret**، أنشئ:
`SUPABASE_URL` و `SUPABASE_ANON_KEY`. ثم شغّل **Build APK**.

## اختبار الأمان (RLS)
على أي PostgreSQL فيه مخطط `auth` (مثل Supabase CLI المحلي):
```bash
psql -v ON_ERROR_STOP=1 -f supabase/tests/rls_test.sql
```
النتيجة المتوقعة: `ALL RLS TESTS PASSED`.
