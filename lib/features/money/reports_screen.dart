import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/core/utils/currency_formatter.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';

const _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int d) => setState(() => _month = DateTime(_month.year, _month.month + d));

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    bool inMonth(DateTime d) => d.year == _month.year && d.month == _month.month;

    final expenses = data.expenses.where((e) => inMonth(e.date)).toList();
    final spent = expenses.fold(0.0, (a, e) => a + e.amount);

    final byStore = <String, double>{};
    for (final e in expenses) {
      final k = e.store.isEmpty ? 'غير محدد' : e.store;
      byStore[k] = (byStore[k] ?? 0) + e.amount;
    }
    final stores = byStore.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final consumed = <String, double>{};
    for (final m in data.movements.where((m) => inMonth(m.at) && m.reason == 'consume')) {
      consumed[m.name] = (consumed[m.name] ?? 0) + m.delta.abs();
    }
    final top = consumed.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final wasteValue = data.movements
        .where((m) => inMonth(m.at) && m.reason == 'waste')
        .fold(0.0, (a, m) => a + m.value);
    final stockValue = data.products.fold(0.0, (a, p) => a + p.price * p.qty);

    // آخر 6 أشهر
    final last6 = [
      for (var i = 5; i >= 0; i--) DateTime(_month.year, _month.month - i),
    ];
    final totals = [for (final m in last6) data.spentInMonth(m)];
    final maxTotal = totals.fold(0.0, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والإحصائيات')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_right)),
              Text('${_months[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_left)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _Kpi('المصروف', formatMoney(spent), Icons.payments_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _Kpi('الميزانية', data.budget == 0 ? '—' : formatMoney(data.budget), Icons.account_balance_wallet_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Kpi('قيمة الهدر', formatMoney(wasteValue), Icons.delete_outline)),
              const SizedBox(width: 12),
              Expanded(child: _Kpi('قيمة المخزون', formatMoney(stockValue), Icons.inventory_2_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _Section('المصروف آخر 6 أشهر'),
          AppCard(
            child: SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < last6.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(totals[i] == 0 ? '' : totals[i].round().toString(),
                              style: const TextStyle(fontSize: 10)),
                          const SizedBox(height: 2),
                          Container(
                            height: maxTotal == 0 ? 2 : 90 * (totals[i] / maxTotal) + 2,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: last6[i] == _month ? AppColors.green : AppColors.greenLeaf,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_months[last6[i].month - 1].substring(0, 3),
                              style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section('حسب المتجر'),
          AppCard(
            child: stores.isEmpty
                ? const Text('لا بيانات لهذا الشهر', style: TextStyle(color: AppColors.textSecondary))
                : Column(
                    children: [
                      for (final s in stores.take(8))
                        _BarRow(label: s.key, value: s.value, max: stores.first.value, text: formatMoney(s.value)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _Section('الأكثر استهلاكاً'),
          AppCard(
            child: top.isEmpty
                ? const Text('لا استهلاك مسجّل هذا الشهر', style: TextStyle(color: AppColors.textSecondary))
                : Column(
                    children: [
                      for (final s in top.take(8))
                        _BarRow(label: s.key, value: s.value, max: top.first.value, text: fmtQty(s.value)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.t);
  final String t;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.greenDark)),
      );
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            Icon(icon, color: AppColors.green),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max, required this.text});
  final String label;
  final double value;
  final double max;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: max == 0 ? 0 : value / max,
                minHeight: 8,
                backgroundColor: const Color(0xFFE3E8E3),
                valueColor: const AlwaysStoppedAnimation(AppColors.green),
              ),
            ),
          ],
        ),
      );
}
