import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/features/inventory/product_form.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// ماسح الباركود: منتج معروف ← إضافة/استهلاك سريع، غير معروف ← نموذج إضافة بالباركود.
class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends ConsumerState<BarcodeScreen> {
  final _controller = MobileScannerController(formats: const [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.qrCode,
  ]);
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handle(String code) async {
    if (_busy) return;
    _busy = true;
    await _controller.stop();
    if (!mounted) return;
    final notifier = ref.read(dataProvider.notifier);
    final p = notifier.productByBarcode(code);
    if (p == null) {
      final add = await confirm(context, 'باركود جديد ($code). إضافته كمنتج؟', yes: 'إضافة');
      if (add && mounted) await showProductForm(context, ref, barcode: code);
    } else {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => Consumer(builder: (ctx, ref, _) {
          final cur = ref.watch(dataProvider).products.firstWhere((x) => x.id == p.id, orElse: () => p);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(cur.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('الكمية الحالية: ${fmtQty(cur.qty)} ${cur.unit}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => notifier.adjust(cur, 1, 'add'),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة واحد'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: cur.qty <= 0 ? null : () => notifier.adjust(cur, -1, 'consume'),
                        icon: const Icon(Icons.remove),
                        label: const Text('استهلاك واحد'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      );
    }
    _busy = false;
    if (mounted) await _controller.start();
  }

  Future<void> _manual() async {
    final r = await showForm(context, title: 'إدخال الباركود يدوياً', fields: const [
      FieldSpec('code', 'رقم الباركود', required: true),
    ]);
    if (r != null) await _handle(r['code']!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ماسح الباركود'), actions: [
        IconButton(
          tooltip: 'إدخال يدوي',
          icon: const Icon(Icons.keyboard),
          onPressed: _manual,
        ),
        IconButton(
          tooltip: 'الفلاش',
          icon: const Icon(Icons.flash_on),
          onPressed: () => _controller.toggleTorch(),
        ),
      ]),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              for (final b in capture.barcodes) {
                final v = b.rawValue;
                if (v != null && v.isNotEmpty) {
                  _handle(v);
                  break;
                }
              }
            },
            errorBuilder: (context, error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text('تعذّر تشغيل الكاميرا. اسمح للتطبيق باستخدامها من إعدادات الهاتف، أو أدخل الباركود يدوياً.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _manual, child: const Text('إدخال يدوي')),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text('وجّه الكاميرا نحو الباركود',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
