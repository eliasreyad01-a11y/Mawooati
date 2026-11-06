import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/sections.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';

/// كل الأقسام مجمّعة. المنفَّذ يفتح شاشته، وغير المنفَّذ يعرض المرحلة المتوقعة صراحةً.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AppSection>>{};
    for (final s in sections) {
      groups.putIfAbsent(s.group, () => []).add(s);
    }
    return Scaffold(
      appBar: AppBar(title: const Text(S.navMore)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final e in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(e.key,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark)),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final s in e.value)
                    ListTile(
                      minTileHeight: AppSpacing.minTouch,
                      leading: Icon(s.icon, color: AppColors.greenDark),
                      title: Text(s.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: s.isBuilt ? null : Text('${S.comingIn} المرحلة ${s.phase}'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.push(s.path),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
