import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/session/session_gate.dart';
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
          ListenableBuilder(
            listenable: ref.watch(sessionGateProvider),
            builder: (context, _) {
              final signedIn = ref.read(sessionGateProvider).signedIn;
              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: signedIn
                      ? [
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('الحساب'),
                            subtitle: Text(
                                ref.read(authRepositoryProvider).email ?? ''),
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('تسجيل الخروج'),
                            onTap: () =>
                                ref.read(authRepositoryProvider).signOut(),
                          ),
                        ]
                      : [
                          const ListTile(
                            leading: Icon(Icons.person_outline),
                            title: Text('أنت تستخدم التطبيق بدون حساب'),
                            subtitle: Text(
                                'تسجيل الدخول اختياري، لمزامنة بياناتك ومشاركتها مع العائلة.'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.login),
                            title: const Text('تسجيل الدخول / إنشاء حساب'),
                            onTap: () => context.push('/login'),
                          ),
                        ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
