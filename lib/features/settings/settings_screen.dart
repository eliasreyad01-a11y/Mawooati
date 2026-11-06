import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final systemReduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text(S.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text(S.reduceMotion,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(systemReduce
                  ? 'مفعّل أيضاً من إعدادات الجهاز'
                  : S.reduceMotionSub),
              value: settings.reduceMotion || systemReduce,
              onChanged: systemReduce
                  ? null
                  : (v) => ref.read(settingsProvider.notifier).setReduceMotion(v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('الحساب'),
                  subtitle: Text(ref.watch(authRepositoryProvider).email ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('تسجيل الخروج'),
                  onTap: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
