import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';
import 'package:share_plus/share_plus.dart';

/// نسخ احتياطي: تصدير كل البيانات كنص JSON (مشاركة/نسخ) واستعادتها بلصقه.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الصق نص النسخة الاحتياطية. سيُستبدل كل ما في التطبيق الآن.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(controller: ctrl, maxLines: 6, minLines: 3),
            TextButton.icon(
              onPressed: () async {
                final d = await Clipboard.getData(Clipboard.kTextPlain);
                ctrl.text = d?.text ?? '';
              },
              icon: const Icon(Icons.paste),
              label: const Text('لصق من الحافظة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('استعادة')),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    final ok = ref.read(dataProvider.notifier).importJson(text);
    snack(context, ok ? 'تمت الاستعادة بنجاح' : 'النص غير صالح كنسخة احتياطية');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            color: AppColors.greenSoft,
            child: Text(
                'بياناتك محفوظة على هذا الجهاز: ${data.products.length} منتج، ${data.expenses.length} مصروف، '
                '${data.notes.length} ملاحظة. احتفظ بنسخة احتياطية قبل تغيير الهاتف أو حذف التطبيق.',
                style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Share.share(ref.read(dataProvider.notifier).exportJson(),
                subject: 'نسخة مؤونتي الاحتياطية'),
            icon: const Icon(Icons.ios_share),
            label: const Text('تصدير ومشاركة النسخة (واتساب، بريد، ملاحظات...)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: ref.read(dataProvider.notifier).exportJson()));
              if (context.mounted) snack(context, 'نُسخت النسخة الاحتياطية');
            },
            icon: const Icon(Icons.copy),
            label: const Text('نسخ النسخة إلى الحافظة'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.restore),
            label: const Text('استعادة من نسخة'),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              if (await confirm(context, 'مسح كل بيانات التطبيق نهائياً؟ لا يمكن التراجع.', yes: 'مسح الكل')) {
                ref.read(dataProvider.notifier).resetAll();
                if (context.mounted) snack(context, 'تم مسح البيانات');
              }
            },
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('مسح كل البيانات'),
          ),
          const SizedBox(height: 8),
          const Text(
              'الصور المرفقة بالفواتير تبقى على الجهاز ولا تدخل في النسخة النصية.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
