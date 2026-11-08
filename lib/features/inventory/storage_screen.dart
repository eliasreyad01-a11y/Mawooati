import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

const _kinds = {
  'fridge': 'ثلاجة',
  'freezer': 'فريزر',
  'pantry': 'مخزن',
  'cabinet': 'خزانة',
  'other': 'آخر',
};
const _kindIcons = {
  'fridge': Icons.kitchen_outlined,
  'freezer': Icons.ac_unit,
  'pantry': Icons.inventory_2_outlined,
  'cabinet': Icons.door_sliding_outlined,
  'other': Icons.place_outlined,
};

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [StorageLocation? l]) async {
    final r = await showForm(context, title: l == null ? 'مكان تخزين جديد' : 'تعديل المكان', fields: [
      FieldSpec('name', 'الاسم', required: true, initial: l?.name ?? ''),
      FieldSpec('kind', 'النوع',
          kind: FieldKind.choice,
          options: _kinds.values.toList(),
          initial: _kinds[l?.kind ?? 'other']!),
    ]);
    if (r == null) return;
    final kind = _kinds.entries.firstWhere((e) => e.value == r['kind'], orElse: () => const MapEntry('other', '')).key;
    ref.read(dataProvider.notifier).saveLocation(
        StorageLocation(id: l?.id ?? newId(), name: r['name']!, kind: kind));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('أماكن التخزين')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('مكان جديد'),
      ),
      body: data.locations.isEmpty
          ? const EmptyState(
              icon: Icons.kitchen_outlined,
              title: 'لا توجد أماكن',
              body: 'أضف الثلاجة أو المخزن لتنظيم منتجاتك.')
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final l in data.locations) ...[
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(_kindIcons[l.kind] ?? Icons.place_outlined,
                          color: AppColors.greenDark),
                      title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${data.products.where((p) => p.locationId == l.id).length} منتج • ${_kinds[l.kind]}'),
                      onTap: () => _edit(context, ref, l),
                      trailing: IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await confirm(context,
                              'حذف "${l.name}"؟ المنتجات فيه ستبقى بدون مكان.', yes: 'حذف')) {
                            ref.read(dataProvider.notifier).deleteLocation(l.id);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}
