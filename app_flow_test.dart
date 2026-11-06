import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawoonati/app.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<void> _pump(WidgetTester t, List<Override> o) =>
    t.pumpWidget(ProviderScope(overrides: o, child: const MawoonatiApp()));

void main() {
  testWidgets('splash leads to RTL home with honest empty state', (tester) async {
    await _pump(tester, await testOverrides(prefs: {}));
    expect(find.text('منزلك أذكى.. وحياتك أسهل'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('مرحباً بك في مؤونتي'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
    expect(dir, TextDirection.rtl);
    expect(find.text('لم تُحدَّد بعد'), findsNWidgets(2));
    expect(find.text('تصوير الفواتير'), findsOneWidget);
  });

  testWidgets('reduce motion skips the long splash', (tester) async {
    await _pump(tester, await testOverrides());
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بك في مؤونتي'), findsOneWidget);
  });

  testWidgets('More lists sections; unbuilt one shows its phase', (tester) async {
    await _pump(tester, await testOverrides());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ماسح الباركود'), 100);
    await tester.tap(find.text('ماسح الباركود'));
    await tester.pumpAndSettle();
    expect(find.textContaining('المرحلة 4'), findsOneWidget);
  });

  testWidgets('reduce-motion toggle persists', (tester) async {
    await _pump(tester, await testOverrides());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reduce_motion'), isFalse);
  });

  testWidgets('signed-out user is sent to login, not home', (tester) async {
    await _pump(tester, await testOverrides(auth: FakeAuth(signedIn: false)));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('مرحباً بك في مؤونتي'), findsNothing);
  });

  testWidgets('signed-in user without household is sent to setup', (tester) async {
    await _pump(tester,
        await testOverrides(households: FakeHouseholds(hasOne: false)));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('إعداد منزلك'), findsOneWidget);
  });

  testWidgets('setup creates household then reaches home', (tester) async {
    await _pump(tester,
        await testOverrides(households: FakeHouseholds(hasOne: false)));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.enterText(find.byType(TextFormField).first, 'بيت العائلة');
    await tester.tap(find.text('إنشاء المنزل'));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بك في مؤونتي'), findsOneWidget);
  });

  testWidgets('login validates input and shows server error', (tester) async {
    final auth = FakeAuth(
        signInError: const AppException('البريد الإلكتروني أو كلمة المرور غير صحيحة.'));
    auth.signedIn = false;
    await _pump(tester, await testOverrides(auth: auth));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('دخول'));
    await tester.pump();
    expect(find.text('أدخل البريد الإلكتروني'), findsOneWidget);
    expect(auth.signInCalls, 0);

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'whatever1');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة.'), findsOneWidget);
  });

  testWidgets('successful login reaches home', (tester) async {
    final auth = FakeAuth(signedIn: false);
    await _pump(tester, await testOverrides(auth: auth));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بك في مؤونتي'), findsOneWidget);
  });
}
