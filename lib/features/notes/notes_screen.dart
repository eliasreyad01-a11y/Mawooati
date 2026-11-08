import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Note? n]) async {
    final r = await showForm(context, title: n == null ? 'ملاحظة جديدة' : 'تعديل الملاحظة', fields: [
      FieldSpec('text', 'الملاحظة', kind: FieldKind.multiline, required: true, initial: n?.text ?? ''),
    ]);
    if (r == null) return;
    ref.read(dataProvider.notifier).saveNote(
        n == null ? Note(id: newId(), text: r['text']!, at: DateTime.now()) : n.copyWith(text: r['text']));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = [...ref.watch(dataProvider).notes]
      ..sort((a, b) => a.pinned == b.pinned ? b.at.compareTo(a.at) : (a.pinned ? -1 : 1));
    return Scaffold(
      appBar: AppBar(title: const Text('الملاحظات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('ملاحظة'),
      ),
      body: notes.isEmpty
          ? const EmptyState(
              icon: Icons.edit_note,
              title: 'لا ملاحظات',
              body: 'دوّن أي شيء يخص البيت أو المشتريات.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      color: n.pinned ? AppColors.greenSoft : Colors.white,
                      child: InkWell(
                        onTap: () => _edit(context, ref, n),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.text, style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(fmtDate(n.at),
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textSecondary)),
                                const Spacer(),
                                IconButton(
                                  tooltip: n.pinned ? 'إلغاء التثبيت' : 'تثبيت',
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(n.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                                  onPressed: () => ref
                                      .read(dataProvider.notifier)
                                      .saveNote(n.copyWith(pinned: !n.pinned)),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    if (await confirm(context, 'حذف الملاحظة؟', yes: 'حذف')) {
                                      ref.read(dataProvider.notifier).deleteNote(n.id);
                                    }
                                  },
                                ),
                              ],
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
