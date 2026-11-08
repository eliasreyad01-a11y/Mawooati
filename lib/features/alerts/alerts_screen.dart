import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

class _Alert {
  const _Alert(this.icon, this.color, this.title, this.sub, this.route);
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final String route;
}

/// التنبيهات تُحسب من بيانات التطبيق: صلاحية، نقص، تذكيرات مستحقة، الميزانية.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final alerts = <_Alert>[
      for (final p in d.expired)
        _Alert(Icons.error_outline, AppColors.danger, '${p.name} منتهي الصلاحية',
            '${fmtQty(p.qty)} ${p.unit} • سجّله كهدر أو تخلّص منه', '/waste'),
      for (final p in d.expiringSoon)
        _Alert(Icons.schedule, AppColors.warning, '${p.name} ينتهي ${p.daysLeft == 0 ? 'اليوم' : 'خلال ${p.daysLeft} يوم'}',
            'الصلاحية ${fmtDate(p.expiry!)}', '/recipes'),
      for (final p in d.lowStock)
        _Alert(Icons.shopping_basket_outlined, AppColors.warning, '${p.name} على وشك النفاد',
            'المتبقي ${fmtQty(p.qty)} ${p.unit} (الحد ${fmtQty(p.minQty)})', '/shopping/daily'),
      for (final r in d.dueReminders)
        _Alert(Icons.alarm, AppColors.green, r.title,
            dateOnly(r.due).isBefore(dateOnly(DateTime.now())) ? 'متأخر • ${fmtDate(r.due)}' : 'اليوم', '/reminders'),
    ];
    if (d.budget > 0) {
      final ratio = d.spentInMonth(DateTime.now()) / d.budget;
      if (ratio >= 1) {
        alerts.add(const _Alert(Icons.account_balance_wallet_outlined, AppColors.danger,
            'تجاوزت ميزانية الشهر', 'راجع المصاريف', '/budget'));
      } else if (ratio >= 0.8) {
        alerts.add(_Alert(Icons.account_balance_wallet_outlined, AppColors.warning,
            'اقتربت من حد الميزانية', 'صرفت ${(ratio * 100).round()}% من ميزانية الشهر', '/budget'));
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text(S.navAlerts)),
      body: alerts.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: S.alertsEmptyTitle,
              body: 'تنبيهات الصلاحية والنقص والتذكيرات والميزانية تظهر هنا.')
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final a in alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: a.color.withValues(alpha: 0.15),
                          child: Icon(a.icon, color: a.color),
                        ),
                        title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(a.sub),
                        onTap: () => context.push(a.route),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
