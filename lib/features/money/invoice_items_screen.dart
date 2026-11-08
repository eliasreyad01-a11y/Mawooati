import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

class _Row {
  _Row({
    required this.name,
    required this.qty,
    required this.unit,
    required this.price,
    required this.locationId,
    required this.expiry,
  });
  String name;
  double qty;
  String unit;
  double price;
  String? locationId;
  DateTime? expiry;
  bool selected = true;
}

/// يحوّل أصناف الفاتورة المقروءة إلى صفوف، ويطابق "place" مع أماكن التخزين الموجودة.
List<Map<String, dynamic>> parseInvoiceItems(List<dynamic> raw) => [
      for (final it in raw)
        if (it is Map && it['name'] != null && it['name'].toString().trim().isNotEmpty)
          Map<String, dynamic>.from(it),
    ];

/// شاشة مراجعة أصناف الفاتورة قبل إضافتها للمخزون، مع مكان التخزين المقترح لكل صنف.
Future<int> showInvoiceItems(
  BuildContext context, {
  required List<Map<String, dynamic>> items,
  required DateTime date,
}) async {
  final n = await Navigator.of(context).push<int>(
    MaterialPageRoute(builder: (_) => _InvoiceItemsPage(items: items, date: date)),
  );
  return n ?? 0;
}

class _InvoiceItemsPage extends ConsumerStatefulWidget {
  const _InvoiceItemsPage({required this.items, required this.date});
  final List<Map<String, dynamic>> items;
  final DateTime date;

  @override
  ConsumerState<_InvoiceItemsPage> createState() => _InvoiceItemsPageState();
}

class _InvoiceItemsPageState extends ConsumerState<_InvoiceItemsPage> {
  late final List<_Row> _rows;

  @override
  void initState() {
    super.initState();
    final locs = ref.read(dataProvider).locations;
    _rows = [
      for (final it in widget.items)
        _Row(
          name: it['name'].toString().trim(),
          qty: _toD(it['qty'], 1) <= 0 ? 1 : _toD(it['qty'], 1),
          unit: _unit(it['unit']),
          price: _toD(it['price'], 0),
          locationId: _matchLoc(locs, it['place']),
          expiry: _toD(it['shelf_life_days'], 0) > 0
              ? widget.date.add(Duration(days: _toD(it['shelf_life_days'], 0).round()))
              : null,
        ),
    ];
  }

  static double _toD(dynamic v, double fallback) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? fallback);

  static String _unit(dynamic u) {
    final s = (u ?? '').toString().trim();
    return s.isEmpty || s == 'null' ? 'حبة' : s;
  }

  static String? _matchLoc(List<StorageLocation> locs, dynamic place) {
    final p = (place ?? '').toString().trim();
    if (p.isEmpty) return null;
    for (final l in locs) {
      if (l.name == p || l.name.contains(p) || p.contains(l.name)) return l.id;
    }
    return null;
  }

  void _save() {
    final n = ref.read(dataProvider.notifier);
    var count = 0;
    for (final r in _rows.where((r) => r.selected)) {
      final existing = ref
          .read(dataProvider)
          .products
          .where((p) => p.name.trim() == r.name)
          .toList();
      if (existing.isNotEmpty) {
        final p = existing.first;
        n.saveProduct(p.copyWith(
          locationId: p.locationId ?? r.locationId,
          price: r.price > 0 ? r.price : p.price,
          expiry: r.expiry ?? p.expiry,
        ));
        n.adjust(ref.read(dataProvider).products.firstWhere((x) => x.id == p.id), r.qty, 'add');
      } else {
        n.saveProduct(Product(
          id: newId(),
          name: r.name,
          qty: r.qty,
          unit: r.unit,
          price: r.price,
          locationId: r.locationId,
          expiry: r.expiry,
        ));
      }
      count++;
    }
    Navigator.pop(context, count);
  }

  @override
  Widget build(BuildContext context) {
    final locs = ref.watch(dataProvider).locations;
    final selected = _rows.where((r) => r.selected).length;
    return Scaffold(
      appBar: AppBar(title: const Text('أصناف الفاتورة')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: selected == 0 ? null : _save,
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text('إضافة $selected صنف للمخزون'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const AppCard(
            color: AppColors.greenSoft,
            child: Text(
                'هذه الأصناف قرأها الذكاء الاصطناعي من الفاتورة مع مكان التخزين المقترح. راجعها وعدّل المكان إن لزم، وألغِ تحديد ما لا تريده.',
                style: TextStyle(height: 1.5)),
          ),
          const SizedBox(height: 12),
          for (final r in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: r.selected,
                      onChanged: (v) => setState(() => r.selected = v ?? false),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            '${fmtQty(r.qty)} ${r.unit}'
                            '${r.price > 0 ? ' • ${r.price.toStringAsFixed(2)} للوحدة' : ''}'
                            '${r.expiry != null ? ' • صلاحية مقدّرة ${fmtDate(r.expiry!)}' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              for (final l in locs)
                                ChoiceChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(l.name),
                                  selected: r.locationId == l.id,
                                  onSelected: (_) => setState(() => r.locationId = l.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
