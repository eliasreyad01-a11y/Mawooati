import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/sections.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/pressable_scale.dart';

/// بطاقة اختصار في الشاشة الرئيسية.
class SectionTile extends StatelessWidget {
  const SectionTile({super.key, required this.section});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => context.push(section.path),
      child: AppCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(section.icon, size: 32, color: AppColors.greenDark),
            const SizedBox(height: 8),
            Text(section.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
