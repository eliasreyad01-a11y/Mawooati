import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/ai/gemini_client.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';

/// مساعد الوصفات: يقترح وصفات مما في المخزون (يبدأ بما قارب على الانتهاء). يحتاج مفتاح Gemini.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  bool _loading = false;
  String? _result;
  String? _error;

  Future<void> _suggest() async {
    final data = ref.read(dataProvider);
    final have = data.products.where((p) => p.qty > 0 && !p.isExpired).toList()
      ..sort((a, b) => (a.daysLeft ?? 9999).compareTo(b.daysLeft ?? 9999));
    if (have.isEmpty) {
      setState(() => _error = 'المخزون فارغ. أضف منتجات أولاً.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final list = have
        .take(40)
        .map((p) =>
            '- ${p.name} (${fmtQty(p.qty)} ${p.unit}${p.daysLeft != null && p.daysLeft! <= 5 ? '، ينتهي قريباً' : ''})')
        .join('\n');
    try {
      final text = await GeminiClient(data.geminiKey, data.geminiModel).generate(
        'أنت مساعد طبخ لعائلة عربية (مطبخ أردني/شامي مفضّل). عندي في المخزون:\n$list\n\n'
        'اقترح 3 وصفات عملية، وأعطِ الأولوية للمكونات التي تنتهي قريباً. '
        'لكل وصفة: الاسم، المكونات الموجودة عندي، ما ينقص إن وُجد، وخطوات مختصرة. '
        'اكتب بالعربية وبنص عادي بدون جداول.',
      );
      setState(() => _result = text.trim());
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    final soon = data.expiringSoon;
    final hasKey = data.geminiKey.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('مساعد الوصفات الذكي')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (soon.isNotEmpty)
            AppCard(
              color: AppColors.greenSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('استخدمها قبل أن تنتهي',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(soon.map((p) => '${p.name} (${p.daysLeft == 0 ? 'اليوم' : '${p.daysLeft} يوم'})').join('، ')),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (!hasKey)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('يحتاج هذا القسم مفتاح Gemini مجاني.',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('احصل عليه من aistudio.google.com ثم الصقه في الإعدادات. لا يُرسل أي شيء بدونه.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  FilledButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text('فتح الإعدادات')),
                ],
              ),
            )
          else
            FilledButton.icon(
              onPressed: _loading ? null : _suggest,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.psychology_outlined),
              label: Text(_loading ? 'جاري التفكير...' : 'اقترح وصفات من مخزوني'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppCard(child: SelectableText(_result!, style: const TextStyle(height: 1.6))),
            ),
        ],
      ),
    );
  }
}
