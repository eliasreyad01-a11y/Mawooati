import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/core/utils/currency_formatter.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

/// قائمة المشتريات: period = daily | monthly. تحديد العنصر "تم الشراء" يسجّل مصروفاً.
class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key, required this.period});
  final String period;

  String get _title => period == 'daily' ? 'المشتريات اليومية' : 'المشتريات الشهرية';

  Future<void> _edit(BuildContext context, WidgetRef ref, [ShoppingItem? s]) async {
    final r = await showForm(context, title: s == null ? 'إضافة عنصر' : 'تعديل العنصر', fields: [
      FieldSpec('name', 'اسم العنصر', required: true, initial: s?.name ?? ''),
      FieldSpec('qty', 'الكمية', kind: FieldKind.number, initial: s == null ? '1' : fmtQty(s.qty)),
      FieldSpec('price', 'السعر المتوقع للوحدة (اختياري)',
          kind: FieldKind.number, initial: s == null || s.price == 0 ? '' : fmtQty(s.price)),
    ]);
    if (r == null) return;
    final qty = parseNum(r['qty'], 1);
    ref.read(dataProvider.notifier).saveShopping(ShoppingItem(
          id: s?.id ?? newId(),
          name: r['name']!,
          qty: qty <= 0 ? 1 : qty,
          price: parseNum(r['price']),
          period: period,
          done: s?.done ?? false,
          doneAt: s?.doneAt,
        ));
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, ShoppingItem s) async {
    final n = ref.read(dataProvider.notifier);
    if (s.done) {
      n.unmarkBought(s);
      return;
    }
    final add = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تم شراء "${s.name}"'),
        content: const Text('هل تريد إضافته إلى المخزون؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم، أضفه')),
        ],
      ),
    );
    if (add == null) return;
    n.markBought(s, addToInventory: add);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final items = data.shopping.where((s) => s.period == period).toList()
      ..sort((a, b) => a.done == b.done ? a.name.compareTo(b.name) : (a.done ? 1 : -1));
    final pending = items.where((s) => !s.done).fold(0.0, (a, s) => a + s.total);
    final bought = items.where((s) => s.done).fold(0.0, (a, s) => a + s.total);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'أضف النواقص من المخزون',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () {
              final names = items.map((s) => s.name.trim()).toSet();
              final low = data.products.where((p) => (p.isLow || p.qty == 0) && !names.contains(p.name.trim()));
              var count = 0;
              for (final p in low) {
                final need = (p.minQty > 0 ? p.minQty * 2 : 1) - p.qty;
                ref.read(dataProvider.notifier).saveShopping(ShoppingItem(
                    id: newId(),
                    name: p.name,
                    qty: need <= 0 ? 1 : need,
                    price: p.price,
                    period: period));
                count++;
              }
              snack(context, count == 0 ? 'لا نواقص جديدة' : 'أُضيف $count عنصر');
            },
          ),
          IconButton(
            tooltip: 'حذف المشتراة',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () => ref.read(dataProvider.notifier).clearBought(period),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة عنصر'),
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: period == 'daily' ? Icons.shopping_cart_outlined : Icons.calendar_month_outlined,
              title: 'القائمة فارغة',
              body: 'أضف ما تريد شراءه. عند الشراء يُسجَّل المصروف تلقائياً.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                AppCard(
                  color: AppColors.greenSoft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat('المتبقي للشراء', formatMoney(pending)),
                      _Stat('تم شراؤه', formatMoney(bought)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final s in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Dismissible(
                        key: ValueKey(s.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          if (s.done) ref.read(dataProvider.notifier).unmarkBought(s);
                          ref.read(dataProvider.notifier).deleteShopping(s.id);
                        },
                        child: ListTile(
                          leading: Checkbox(
                            value: s.done,
                            onChanged: (_) => _toggle(context, ref, s),
                          ),
                          title: Text(s.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: s.done ? TextDecoration.lineThrough : null,
                              )),
                          subtitle: Text(
                              '${fmtQty(s.qty)}${s.price > 0 ? ' × ${formatMoney(s.price)} = ${formatMoney(s.total)}' : ''}'),
                          onTap: s.done ? null : () => _edit(context, ref, s),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      );
}
