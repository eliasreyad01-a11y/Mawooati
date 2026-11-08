import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/core/utils/currency_formatter.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/budget_progress_bar.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

/// الميزانية الشهرية + المصاريف اليدوية وقائمة مصاريف الشهر.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Future<void> _setBudget(BuildContext context, WidgetRef ref, double current) async {
    final r = await showForm(context, title: 'ميزانية الشهر', fields: [
      FieldSpec('b', 'المبلغ', kind: FieldKind.number, required: true,
          initial: current == 0 ? '' : current.toString()),
    ]);
    if (r != null) ref.read(dataProvider.notifier).setBudget(parseNum(r['b']));
  }

  Future<void> _addExpense(BuildContext context, WidgetRef ref) async {
    final r = await showForm(context, title: 'إضافة مصروف', fields: [
      FieldSpec('amount', 'المبلغ', kind: FieldKind.number, required: true),
      FieldSpec('note', 'البيان (مثلاً: خضار)', required: true),
      FieldSpec('store', 'المتجر (اختياري)'),
      FieldSpec('date', 'التاريخ', kind: FieldKind.date, required: true, initial: fmtDate(DateTime.now())),
    ]);
    if (r == null) return;
    ref.read(dataProvider.notifier).saveExpense(Expense(
          id: newId(),
          amount: parseNum(r['amount']),
          date: DateTime.tryParse(r['date']!) ?? DateTime.now(),
          store: r['store'] ?? '',
          source: 'manual',
          note: r['note'] ?? '',
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final now = DateTime.now();
    final spent = data.spentInMonth(now);
    final ratio = data.budget > 0 ? spent / data.budget : null;
    final month = data.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final remaining = data.budget - spent;

    return Scaffold(
      appBar: AppBar(title: const Text('الميزانية')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('مصروف'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('ميزانية هذا الشهر',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () => _setBudget(context, ref, data.budget),
                      child: Text(data.budget == 0 ? 'تحديد' : 'تعديل'),
                    ),
                  ],
                ),
                Text(data.budget == 0 ? 'لم تُحدَّد بعد' : formatMoney(data.budget),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                BudgetProgressBar(value: ratio),
                const SizedBox(height: 8),
                Text(
                  data.budget == 0
                      ? 'المصروف حتى الآن: ${formatMoney(spent)}'
                      : 'المصروف: ${formatMoney(spent)} (${((ratio ?? 0) * 100).round()}%) • '
                          '${remaining >= 0 ? 'المتبقي: ${formatMoney(remaining)}' : 'تجاوزت بمقدار ${formatMoney(-remaining)}'}',
                  style: TextStyle(
                      color: remaining < 0 && data.budget > 0
                          ? AppColors.danger
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('مصاريف هذا الشهر', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (month.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا مصاريف بعد. المشتريات والفواتير تُسجَّل هنا تلقائياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          for (final e in month)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    e.source == 'invoice'
                        ? Icons.receipt_long_outlined
                        : e.source == 'shopping'
                            ? Icons.shopping_cart_outlined
                            : Icons.payments_outlined,
                    color: AppColors.greenDark,
                  ),
                  title: Text(e.note.isEmpty ? (e.store.isEmpty ? 'مصروف' : e.store) : e.note,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([fmtDate(e.date), if (e.store.isNotEmpty) e.store].join(' • ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatMoney(e.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await confirm(context, 'حذف هذا المصروف؟', yes: 'حذف')) {
                            ref.read(dataProvider.notifier).deleteExpense(e.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
