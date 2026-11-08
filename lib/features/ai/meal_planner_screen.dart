import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/ai/gemini_client.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';

const _days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
const _slots = {'b': 'فطور', 'l': 'غداء', 'd': 'عشاء'};

/// مخطط وجبات لـ 7 أيام: تعبئة يدوية، أو اقتراح كامل بالذكاء الاصطناعي (يحتاج مفتاح Gemini).
class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  bool _loading = false;

  List<DateTime> get _week {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    return [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
  }

  String _dayName(DateTime d) => _days[d.weekday % 7];

  Future<void> _edit(DateTime d, String slot) async {
    final key = '${fmtDate(d)}|$slot';
    final cur = ref.read(dataProvider).meals[key] ?? '';
    final r = await showForm(context, title: '${_dayName(d)} - ${_slots[slot]}', fields: [
      FieldSpec('m', 'الوجبة (اتركه فارغاً للمسح)', initial: cur),
    ]);
    if (r != null) ref.read(dataProvider.notifier).setMeal(key, r['m'] ?? '');
  }

  Future<void> _suggest() async {
    final data = ref.read(dataProvider);
    if (data.geminiKey.isEmpty) {
      snack(context, 'أضف مفتاح Gemini من الإعدادات أولاً.');
      return;
    }
    setState(() => _loading = true);
    final have = data.products.where((p) => p.qty > 0 && !p.isExpired).take(40).map((p) => p.name).join('، ');
    try {
      final text = await GeminiClient(data.geminiKey, data.geminiModel).generate(
        'خطط وجبات لعائلة عربية لمدة 7 أيام (مطبخ أردني/شامي مفضّل). '
        'المتوفر في البيت: ${have.isEmpty ? 'لا شيء محدد' : have}. '
        'أجب بـ JSON فقط بالشكل: {"days":[{"b":"فطور","l":"غداء","d":"عشاء"}, ...7 عناصر]} '
        'بأسماء وجبات قصيرة بالعربية.',
      );
      final j = GeminiClient.extractJson(text);
      final days = (j?['days'] as List?) ?? const [];
      if (days.isEmpty) throw const AppException('لم أفهم رد الذكاء الاصطناعي. حاول مرة أخرى.');
      final week = _week;
      final entries = <String, String>{};
      for (var i = 0; i < week.length && i < days.length; i++) {
        final m = days[i];
        if (m is! Map) continue;
        for (final s in _slots.keys) {
          final v = m[s];
          if (v != null && v.toString().trim().isNotEmpty) {
            entries['${fmtDate(week[i])}|$s'] = v.toString().trim();
          }
        }
      }
      ref.read(dataProvider.notifier).setMeals(entries);
    } on AppException catch (e) {
      if (mounted) snack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(dataProvider).meals;
    return Scaffold(
      appBar: AppBar(title: const Text('مخطط الوجبات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _suggest,
        icon: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.auto_awesome),
        label: Text(_loading ? 'جاري التخطيط...' : 'اقتراح أسبوع بالذكاء'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        children: [
          for (final d in _week)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_dayName(d)}  ${fmtDate(d)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                    const SizedBox(height: 6),
                    for (final s in _slots.entries)
                      InkWell(
                        onTap: () => _edit(d, s.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 56,
                                  child: Text(s.value,
                                      style: const TextStyle(color: AppColors.textSecondary))),
                              Expanded(
                                child: Text(
                                  meals['${fmtDate(d)}|${s.key}'] ?? 'اضغط للإضافة',
                                  style: TextStyle(
                                    fontWeight: meals.containsKey('${fmtDate(d)}|${s.key}')
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: meals.containsKey('${fmtDate(d)}|${s.key}')
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
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
