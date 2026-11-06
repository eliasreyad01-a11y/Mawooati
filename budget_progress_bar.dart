import 'package:flutter/material.dart';
import 'package:mawoonati/core/theme/app_colors.dart';

/// شريط استهلاك الميزانية. [value] بين 0 و1، أو null عند عدم وجود ميزانية.
/// اللون: أخضر ثم برتقالي (≥80%) ثم أحمر (≥100%).
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({super.key, required this.value});

  final double? value;

  Color get _color {
    final v = value ?? 0;
    if (v >= 1) return AppColors.danger;
    if (v >= 0.8) return AppColors.warning;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final v = (value ?? 0).clamp(0.0, 1.0);
    return Semantics(
      label: value == null ? 'لا توجد ميزانية' : 'نسبة الاستهلاك ${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 10,
          backgroundColor: const Color(0xFFE3E8E3),
          valueColor: AlwaysStoppedAnimation(_color),
        ),
      ),
    );
  }
}
