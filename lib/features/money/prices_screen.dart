import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/core/utils/currency_formatter.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

/// مقارنة الأسعار: تسجّل سعر المنتج في كل متجر ويظهر الأرخص. تُغذّى تلقائياً من الفواتير المقروءة بالذكاء.
class PricesScreen extends ConsumerWidget {
  const PricesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final r = await showForm(context, title: 'إضافة سعر', fields: [
      FieldSpec('item', 'المنتج', required: true),
      FieldSpec('store', 'المتجر', required: true),
      FieldSpec('price', 'السعر', kind: FieldKind.number, required: true),
      FieldSpec('date', 'التاريخ', kind: FieldKind.date, required: true, initial: fmtDate(DateTime.now())),
    ]);
    if (r == null) return;
    ref.read(dataProvider.notifier).addPrices([
      PricePoint(
        id: newId(),
        item: r['item']!,
        store: r['store']!,
        price: parseNum(r['price']),
        date: DateTime.tryParse(r['date']!) ?? DateTime.now(),
      )
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final groups = <String, List<PricePoint>>{};
    for (final p in data.prices) {
      groups.putIfAbsent(p.item.trim(), () => []).add(p);
    }
    final keys = groups.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة الأسعار')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة سعر'),
      ),
      body: keys.isEmpty
          ? const EmptyState(
              icon: Icons.price_change_outlined,
              title: 'لا أسعار بعد',
              body: 'سجّل سعر المنتج في أكثر من متجر لتعرف الأرخص. الفواتير المقروءة بالذكاء الاصطناعي تضيفها تلقائياً.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                for (final k in keys) _ItemCard(item: k, points: groups[k]!),
              ],
            ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item, required this.points});
  final String item;
  final List<PricePoint> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // آخر سعر لكل متجر
    final latest = <String, PricePoint>{};
    for (final p in points) {
      final cur = latest[p.store];
      if (cur == null || p.date.isAfter(cur.date)) latest[p.store] = p;
    }
    final sorted = latest.values.toList()..sort((a, b) => a.price.compareTo(b.price));
    final best = sorted.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(item, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
              'الأرخص: ${best.store} • ${formatMoney(best.price)}${sorted.length > 1 ? ' (من ${sorted.length} متاجر)' : ''}',
              style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
          children: [
            for (final p in points.reversed)
              ListTile(
                dense: true,
                title: Text('${p.store} • ${formatMoney(p.price)}'),
                subtitle: Text(fmtDate(p.date)),
                trailing: IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(dataProvider.notifier).deletePrice(p.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
