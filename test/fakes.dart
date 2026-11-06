import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/features/household/household_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuth implements AuthRepository {
  FakeAuth({this.signedIn = false, this.signInError});
  bool signedIn;
  AppException? signInError;
  final _c = StreamController<void>.broadcast();
  int signInCalls = 0;

  @override
  bool get isSignedIn => signedIn;
  @override
  String? get email => signedIn ? 'user@test.com' : null;
  @override
  Stream<void> get changes => _c.stream;

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    if (signInError != null) throw signInError!;
    signedIn = true;
    _c.add(null);
  }

  @override
  Future<bool> signUp(String email, String password, String displayName) async => true;
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> signOut() async {
    signedIn = false;
    _c.add(null);
  }
}

class FakeHouseholds implements HouseholdRepository {
  FakeHouseholds({this.hasOne = true});
  bool hasOne;
  @override
  Future<List<Household>> myHouseholds() async =>
      hasOne ? const [Household(id: '1', name: 'بيتنا', currency: 'JOD')] : [];
  @override
  Future<String> createHousehold({required String name, required String currency}) async {
    hasOne = true;
    return '1';
  }
}

Future<List<Override>> testOverrides({
  Map<String, Object> prefs = const {'reduce_motion': true},
  FakeAuth? auth,
  FakeHouseholds? households,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  return [
    sharedPrefsProvider.overrideWithValue(p),
    authRepositoryProvider.overrideWithValue(auth ?? FakeAuth(signedIn: true)),
    householdRepositoryProvider.overrideWithValue(households ?? FakeHouseholds()),
  ];
}
