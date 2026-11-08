import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

const productUnits = ['حبة', 'كغم', 'غم', 'لتر', 'علبة', 'كيس', 'عبوة', 'ربطة'];

String _fmtNum(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

/// إضافة/تعديل منتج. [barcode] يُعبّأ مسبقاً عند القدوم من الماسح.
Future<void> showProductForm(
  BuildContext context,
  WidgetRef ref, {
  Product? product,
  String barcode = '',
}) async {
  final data = ref.read(dataProvider);
  final locNames = [for (final l in data.locations) l.name];
  final currentLoc = data.locations.where((l) => l.id == product?.locationId).toList();
  final r = await showForm(
    context,
    title: product == null ? 'إضافة منتج' : 'تعديل المنتج',
    fields: [
      FieldSpec('name', 'اسم المنتج', required: true, initial: product?.name ?? ''),
      FieldSpec('qty', 'الكمية', kind: FieldKind.number, initial: product == null ? '1' : _fmtNum(product.qty)),
      FieldSpec('unit', 'الوحدة',
          kind: FieldKind.choice, options: productUnits, initial: product?.unit ?? 'حبة'),
      FieldSpec('min', 'حد النقص (تنبيه عند الوصول إليه)',
          kind: FieldKind.number, initial: product == null || product.minQty == 0 ? '' : _fmtNum(product.minQty)),
      if (locNames.isNotEmpty)
        FieldSpec('loc', 'مكان التخزين',
            kind: FieldKind.choice,
            options: locNames,
            initial: currentLoc.isEmpty ? '' : currentLoc.first.name),
      FieldSpec('cat', 'التصنيف (اختياري)', initial: product?.category ?? ''),
      FieldSpec('exp', 'تاريخ الصلاحية',
          kind: FieldKind.date, initial: product?.expiry == null ? '' : fmtDate(product!.expiry!)),
      FieldSpec('price', 'سعر الوحدة (اختياري)',
          kind: FieldKind.number, initial: product == null || product.price == 0 ? '' : _fmtNum(product.price)),
      FieldSpec('barcode', 'الباركود (اختياري)', initial: product?.barcode ?? barcode),
    ],
  );
  if (r == null) return;
  final loc = data.locations.where((l) => l.name == r['loc']).toList();
  final p = Product(
    id: product?.id ?? newId(),
    name: r['name']!,
    qty: parseNum(r['qty']),
    unit: (r['unit'] ?? '').isEmpty ? 'حبة' : r['unit']!,
    minQty: parseNum(r['min']),
    locationId: loc.isEmpty ? null : loc.first.id,
    category: r['cat'] ?? '',
    expiry: (r['exp'] ?? '').isEmpty ? null : DateTime.tryParse(r['exp']!),
    price: parseNum(r['price']),
    barcode: r['barcode'] ?? '',
  );
  if (product != null && p.qty != product.qty) {
    // تعديل الكمية يدوياً يُسجَّل كحركة تعديل.
    ref.read(dataProvider.notifier).saveProduct(p.copyWith(qty: product.qty));
    ref.read(dataProvider.notifier).adjust(p.copyWith(qty: product.qty), p.qty - product.qty, 'adjust');
  } else {
    ref.read(dataProvider.notifier).saveProduct(p);
  }
}

/// يسأل عن كمية ثم يطبّق الحركة (استهلاك/هدر).
Future<void> askAndAdjust(
  BuildContext context,
  WidgetRef ref,
  Product p, {
  required String reason,
}) async {
  final title = reason == 'waste' ? 'تسجيل هدر: ${p.name}' : 'استهلاك: ${p.name}';
  final r = await showForm(context, title: title, submitLabel: 'تأكيد', fields: [
    FieldSpec('q', 'الكمية (${p.unit})', kind: FieldKind.number, initial: '1', required: true),
  ]);
  if (r == null) return;
  final q = parseNum(r['q']);
  if (q <= 0) return;
  ref.read(dataProvider.notifier).adjust(p, -q, reason);
}
