import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mawoonati/core/ai/gemini_client.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/core/utils/currency_formatter.dart';
import 'package:mawoonati/features/common/empty_state.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';
import 'package:path_provider/path_provider.dart';

/// تصوير الفواتير: صورة + مبلغ ومتجر. مع مفتاح Gemini تُقرأ الفاتورة تلقائياً.
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  Future<void> _capture(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1800, imageQuality: 85);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await picked.readAsBytes();
      await File(path).writeAsBytes(bytes);
      if (!context.mounted) return;

      Map<String, dynamic>? ai;
      final data = ref.read(dataProvider);
      if (data.geminiKey.isNotEmpty) {
        ai = await _readWithAi(context, data.geminiKey, data.geminiModel, bytes);
      }
      if (!context.mounted) return;

      final items = (ai?['items'] as List?) ?? const [];
      final itemsText = [
        for (final it in items)
          if (it is Map) '${it['name']} × ${it['qty'] ?? 1}',
      ].join('، ');
      final r = await showForm(context, title: 'بيانات الفاتورة', fields: [
        FieldSpec('store', 'المتجر', initial: (ai?['store'] ?? '').toString()),
        FieldSpec('amount', 'المبلغ الإجمالي',
            kind: FieldKind.number, required: true, initial: ai?['total'] == null ? '' : ai!['total'].toString()),
        FieldSpec('date', 'التاريخ',
            kind: FieldKind.date,
            required: true,
            initial: (DateTime.tryParse((ai?['date'] ?? '').toString()) != null)
                ? ai!['date'].toString()
                : fmtDate(DateTime.now())),
        FieldSpec('note', 'ملاحظات / المشتريات', kind: FieldKind.multiline, initial: itemsText),
      ]);
      if (r == null) return;
      final date = DateTime.tryParse(r['date']!) ?? DateTime.now();
      final n = ref.read(dataProvider.notifier);
      n.saveExpense(Expense(
        id: newId(),
        amount: parseNum(r['amount']),
        date: date,
        store: r['store'] ?? '',
        source: 'invoice',
        note: r['note'] ?? '',
        imagePath: path,
      ));
      // أسعار الأصناف المقروءة تغذّي مقارنة الأسعار.
      final store = (r['store'] ?? '').isEmpty ? 'غير محدد' : r['store']!;
      final pts = <PricePoint>[
        for (final it in items)
          if (it is Map && it['name'] != null && num.tryParse('${it['price']}') != null && (num.parse('${it['price']}')) > 0)
            PricePoint(
                id: newId(),
                item: it['name'].toString(),
                store: store,
                price: num.parse('${it['price']}').toDouble(),
                date: date),
      ];
      if (pts.isNotEmpty) n.addPrices(pts);
      if (context.mounted) snack(context, 'تم حفظ الفاتورة${pts.isNotEmpty ? ' وأسعار ${pts.length} صنف' : ''}');
    } catch (e) {
      if (context.mounted) {
        snack(context, e is AppException ? e.message : 'تعذّر فتح الكاميرا أو الصورة.');
      }
    }
  }

  Future<Map<String, dynamic>?> _readWithAi(
      BuildContext context, String key, String model, Uint8List bytes) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Expanded(child: Text('جاري قراءة الفاتورة...')),
        ]),
      ),
    );
    Map<String, dynamic>? out;
    String? err;
    try {
      final text = await GeminiClient(key, model).generate(
        'Read this shopping receipt. Reply with JSON only, no prose: '
        '{"store": string, "total": number, "date": "YYYY-MM-DD", '
        '"items": [{"name": string, "qty": number, "price": number}]} '
        'where price is the unit price. Keep item names in their original language. '
        'Use null for anything unreadable.',
        image: bytes,
      );
      out = GeminiClient.extractJson(text);
      if (out == null) err = 'لم أستطع قراءة الفاتورة. أدخل البيانات يدوياً.';
    } on AppException catch (e) {
      err = e.message;
    }
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (err != null && context.mounted) snack(context, err);
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    final list = data.expenses.where((e) => e.source == 'invoice').toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: const Text('تصوير الفواتير')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('تصوير بالكاميرا'),
                onTap: () {
                  Navigator.pop(ctx);
                  _capture(context, ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار من المعرض'),
                onTap: () {
                  Navigator.pop(ctx);
                  _capture(context, ref, ImageSource.gallery);
                },
              ),
            ]),
          ),
        ),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('فاتورة جديدة'),
      ),
      body: list.isEmpty
          ? EmptyState(
              icon: Icons.photo_camera_outlined,
              title: 'لا فواتير بعد',
              body: data.geminiKey.isEmpty
                  ? 'صوّر الفاتورة وأدخل مبلغها. لقراءتها تلقائياً أضف مفتاح Gemini من الإعدادات.'
                  : 'صوّر الفاتورة وسيقرأ الذكاء الاصطناعي بياناتها.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                for (final e in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: _Thumb(path: e.imagePath),
                        title: Text(e.store.isEmpty ? 'فاتورة' : e.store,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                            [fmtDate(e.date), if (e.note.isNotEmpty) e.note].join(' • '),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(formatMoney(e.amount),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirm(context, 'حذف الفاتورة؟', yes: 'حذف')) {
                                ref.read(dataProvider.notifier).deleteExpense(e.id);
                                final p = e.imagePath;
                                if (p != null) {
                                  try {
                                    await File(p).delete();
                                  } catch (_) {}
                                }
                              }
                            },
                          ),
                        ]),
                        onTap: e.imagePath == null
                            ? null
                            : () => showDialog<void>(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: InteractiveViewer(
                                      child: Image.file(File(e.imagePath!),
                                          errorBuilder: (_, __, ___) => const Padding(
                                              padding: EdgeInsets.all(24),
                                              child: Text('الصورة غير متوفرة'))),
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final box = BoxDecoration(
        color: AppColors.greenSoft, borderRadius: BorderRadius.circular(10));
    if (path == null) {
      return Container(
          width: 48, height: 48, decoration: box,
          child: const Icon(Icons.receipt_long_outlined, color: AppColors.greenDark));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(File(path!),
          width: 48, height: 48, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              width: 48, height: 48, decoration: box,
              child: const Icon(Icons.receipt_long_outlined, color: AppColors.greenDark))),
    );
  }
}
