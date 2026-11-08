import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

/// تذكيرات داخل التطبيق: المستحق والمتأخر يظهر في تبويب التنبيهات.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Reminder? r]) async {
    final v = await showForm(context, title: r == null ? 'تذكير جديد' : 'تعديل التذكير', fields: [
      FieldSpec('title', 'التذكير', required: true, initial: r?.title ?? ''),
      FieldSpec('due', 'التاريخ', kind: FieldKind.date, required: true,
          initial: fmtDate(r?.due ?? DateTime.now())),
    ]);
    if (v == null) return;
    final due = DateTime.tryParse(v['due']!) ?? DateTime.now();
    ref.read(dataProvider.notifier).saveReminder(
        r == null ? Reminder(id: newId(), title: v['title']!, due: due) : r.copyWith(title: v['title'], due: due));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = [...ref.watch(dataProvider).reminders]
      ..sort((a, b) => a.done == b.done ? a.due.compareTo(b.due) : (a.done ? 1 : -1));
    final today = dateOnly(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('التذكيرات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_alarm),
        label: const Text('تذكير'),
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.alarm,
              title: 'لا تذكيرات',
              body: 'أضف تذكيراً (دفع فاتورة، شراء حاجة...). المستحق يظهر في تبويب التنبيهات.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: Checkbox(
                          value: r.done,
                          onChanged: (v) => ref
                              .read(dataProvider.notifier)
                              .saveReminder(r.copyWith(done: v ?? false)),
                        ),
                        title: Text(r.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: r.done ? TextDecoration.lineThrough : null,
                            )),
                        subtitle: Text(
                          dateOnly(r.due).isBefore(today) && !r.done
                              ? 'متأخر • ${fmtDate(r.due)}'
                              : fmtDate(r.due),
                          style: TextStyle(
                              color: dateOnly(r.due).isBefore(today) && !r.done
                                  ? AppColors.danger
                                  : AppColors.textSecondary),
                        ),
                        onTap: () => _edit(context, ref, r),
                        trailing: IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(dataProvider.notifier).deleteReminder(r.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
