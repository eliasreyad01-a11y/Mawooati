import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

const _reasonLabel = {
  'add': 'إضافة',
  'consume': 'استهلاك',
  'waste': 'هدر',
  'adjust': 'تعديل',
};

/// سجل كل حركات المخزون (إضافة/استهلاك/تعديل). الهدر له شاشة خاصة لكنه يظهر هنا أيضاً.
class ConsumptionScreen extends ConsumerWidget {
  const ConsumptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(dataProvider).movements.reversed.toList();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final consumedWeek = list.where((m) => m.reason == 'consume' && m.at.isAfter(weekAgo)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الاستهلاك')),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'السجل فارغ',
              body: 'أي إضافة أو استهلاك للمنتجات يظهر هنا تلقائياً.')
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppCard(
                  color: AppColors.greenSoft,
                  child: Text('حركات استهلاك آخر 7 أيام: $consumedWeek',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                for (final m in list.take(300)) _MovementTile(m: m),
              ],
            ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.m});
  final Movement m;

  @override
  Widget build(BuildContext context) {
    final plus = m.delta > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (plus ? AppColors.green : AppColors.warning).withValues(alpha: 0.15),
            child: Icon(plus ? Icons.add : Icons.remove,
                color: plus ? AppColors.green : AppColors.warning),
          ),
          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${_reasonLabel[m.reason] ?? m.reason} • ${fmtDate(m.at)}'),
          trailing: Text('${plus ? '+' : '-'}${fmtQty(m.delta.abs())} ${m.unit}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
