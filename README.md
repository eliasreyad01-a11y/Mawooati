# مؤونتي AI – Mawoonati AI

منزلك أذكى.. وحياتك أسهل. تطبيق Flutter (Android + iOS)، عربي RTL.

## التشغيل (يحتاج Flutter ≥ 3.33)
```bash
cd mawoonati
flutter create --project-name mawoonati --org com.mawoonati --platforms android,ios .
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
الأمر `flutter create .` يُنشئ مجلدي android وios فقط ولا يستبدل ملفات lib.

الحالة الحالية: المرحلة 2 (الحسابات وقاعدة البيانات). انظر docs/SUPABASE_SETUP.md وdocs/PHASE_2_REPORT.md.
