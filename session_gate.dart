import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/features/household/household_repository.dart';

/// يحدد أين يذهب المستخدم: دخول، إعداد منزل، أو الرئيسية.
/// - hasHousehold == null أثناء التحميل (أو عند فشله مع loadFailed).
class SessionGate extends ChangeNotifier {
  SessionGate(this._auth, this._households) {
    _sub = _auth.changes.listen((_) => refresh());
    refresh();
  }

  final AuthRepository _auth;
  final HouseholdRepository _households;
  late final StreamSubscription<void> _sub;
  int _ticket = 0;

  bool signedIn = false;
  bool? hasHousehold;
  bool loadFailed = false;

  Future<void> refresh() async {
    final ticket = ++_ticket;
    signedIn = _auth.isSignedIn;
    loadFailed = false;
    hasHousehold = null;
    notifyListeners();
    if (!signedIn) return;
    try {
      final list = await _households.myHouseholds();
      if (ticket != _ticket) return;
      hasHousehold = list.isNotEmpty;
    } catch (_) {
      if (ticket != _ticket) return;
      loadFailed = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final sessionGateProvider = Provider<SessionGate>((ref) {
  final gate = SessionGate(
    ref.watch(authRepositoryProvider),
    ref.watch(householdRepositoryProvider),
  );
  ref.onDispose(gate.dispose);
  return gate;
});
