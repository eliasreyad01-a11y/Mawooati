import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/features/inventory/product_form.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

String fmtQty(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _q = '';
  String? _locId; // null = الكل

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    final items = data.products.where((p) {
      if (_locId != null && p.locationId != _locId) return false;
      if (_q.isNotEmpty && !p.name.contains(_q) && !p.category.contains(_q)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.navInventory),
        actions: [
          IconButton(
            tooltip: 'ماسح الباركود',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/barcode'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProductForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.trim()),
              decoration: const InputDecoration(
                hintText: 'ابحث عن منتج',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: const Text('الكل'),
                    selected: _locId == null,
                    onSelected: (_) => setState(() => _locId = null),
                  ),
                ),
                for (final l in data.locations)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(l.name),
                      selected: _locId == l.id,
                      onSelected: (_) => setState(() => _locId = l.id),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: data.products.isEmpty ? S.inventoryEmptyTitle : 'لا نتائج',
                    body: data.products.isEmpty
                        ? 'اضغط "إضافة منتج" أو امسح باركود لتبدأ.'
                        : 'جرّب بحثاً أو مكان تخزين آخر.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ProductCard(product: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final data = ref.watch(dataProvider);
    final loc = data.locations.where((l) => l.id == p.locationId).toList();
    final d = p.daysLeft;
    final badges = <Widget>[];
    if (p.qty > 0 && d != null) {
      if (d < 0) {
        badges.add(_Badge('منتهي', AppColors.danger));
      } else if (d <= 3) {
        badges.add(_Badge(d == 0 ? 'ينتهي اليوم' : 'ينتهي خلال $d أيام', AppColors.warning));
      }
    }
    if (p.isLow) badges.add(_Badge('نقص', AppColors.warning));
    if (p.qty == 0) badges.add(_Badge('نفد', AppColors.danger));

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => showProductForm(context, ref, product: p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '${fmtQty(p.qty)} ${p.unit}',
                      if (loc.isNotEmpty) loc.first.name,
                      if (p.expiry != null) 'صلاحية ${fmtDate(p.expiry!)}',
                    ].join(' • '),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (badges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(spacing: 6, children: badges),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'استهلاك واحد',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: p.qty <= 0
                ? null
                : () => ref.read(dataProvider.notifier).adjust(p, -1, 'consume'),
          ),
          IconButton(
            tooltip: 'إضافة واحد',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.green),
            onPressed: () => ref.read(dataProvider.notifier).adjust(p, 1, 'add'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'consume':
                  await askAndAdjust(context, ref, p, reason: 'consume');
                case 'waste':
                  await askAndAdjust(context, ref, p, reason: 'waste');
                case 'edit':
                  await showProductForm(context, ref, product: p);
                case 'delete':
                  if (await confirm(context, 'حذف "${p.name}" نهائياً؟', yes: 'حذف')) {
                    ref.read(dataProvider.notifier).deleteProduct(p.id);
                  }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'consume', child: Text('استهلاك كمية')),
              PopupMenuItem(value: 'waste', child: Text('تسجيل هدر')),
              PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(value: 'delete', child: Text('حذف')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
