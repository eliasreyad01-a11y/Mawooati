import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/core/utils/currency_formatter.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

class WasteScreen extends ConsumerWidget {
  const WasteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final waste = data.movements.where((m) => m.reason == 'waste').toList().reversed.toList();
    final now = DateTime.now();
    final monthValue = waste
        .where((m) => m.at.year == now.year && m.at.month == now.month)
        .fold(0.0, (a, m) => a + m.value);
    final expired = data.expired;

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الهدر')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            color: AppColors.greenSoft,
            child: Row(
              children: [
                const Icon(Icons.delete_outline, color: AppColors.greenDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'قيمة الهدر هذا الشهر: ${formatMoney(monthValue)}\n(تُحسب من أسعار المنتجات المُدخلة)',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (expired.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('منتجات منتهية الصلاحية',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger)),
            const SizedBox(height: 8),
            for (final p in expired)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${fmtQty(p.qty)} ${p.unit} • انتهت ${fmtDate(p.expiry!)}'),
                    trailing: FilledButton(
                      onPressed: () =>
                          ref.read(dataProvider.notifier).adjust(p, -p.qty, 'waste'),
                      child: const Text('سجّل هدر'),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          const Text('السجل', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (waste.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا يوجد هدر مسجّل. هذا جيد!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          for (final m in waste.take(200))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(fmtDate(m.at)),
                  trailing: Text(
                      '${fmtQty(m.delta.abs())} ${m.unit}${m.value > 0 ? '\n${formatMoney(m.value)}' : ''}',
                      textAlign: TextAlign.end),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
