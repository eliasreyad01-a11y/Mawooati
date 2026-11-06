import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يُستبدل في main() بنسخة حقيقية من SharedPreferences.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

class AppSettings {
  const AppSettings({this.reduceMotion = false});
  final bool reduceMotion;
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kReduceMotion = 'reduce_motion';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return AppSettings(reduceMotion: prefs.getBool(_kReduceMotion) ?? false);
  }

  Future<void> setReduceMotion(bool value) async {
    state = AppSettings(reduceMotion: value);
    await ref.read(sharedPrefsProvider).setBool(_kReduceMotion, value);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// تقليل الحركة: من إعداد التطبيق أو من إعداد النظام.
bool shouldReduceMotion(BuildContext context, WidgetRef ref) =>
    ref.watch(settingsProvider).reduceMotion ||
    MediaQuery.disableAnimationsOf(context);
