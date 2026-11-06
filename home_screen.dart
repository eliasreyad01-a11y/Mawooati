import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/sections.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/home/section_tile.dart';
import 'package:mawoonati/shared/widgets/animated_entrance.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/budget_progress_bar.dart';
import 'package:mawoonati/shared/widgets/mawoonati_logo.dart';
import 'package:mawoonati/shared/widgets/pressable_scale.dart';

/// الرئيسية. لا توجد بيانات مالية بعد (تُربط بقاعدة البيانات في المرحلتين 2 و5)،
/// لذلك تعرض حالة فارغة صادقة بدل أرقام وهمية.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const AnimatedEntrance(index: 0, child: _WelcomeCard()),
                const SizedBox(height: AppSpacing.md),
                const AnimatedEntrance(index: 1, child: _SummaryRow()),
                const SizedBox(height: AppSpacing.md),
                const AnimatedEntrance(index: 2, child: _BudgetUsageCard()),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    for (var i = 0; i < quickActionIds.length; i++)
                      AnimatedEntrance(
                        index: 3 + (i ~/ 3),
                        child: SectionTile(section: sectionById(quickActionIds[i])),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.green, AppColors.greenMist, AppColors.background],
          stops: [0, 0.55, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: S.navAlerts,
                  color: Colors.white,
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.go('/alerts'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: S.settings,
                  color: Colors.white,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const LogoMark(size: 96),
            const Text(S.appName,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                    height: 1.1)),
            const Text(S.appNameEn,
                style: TextStyle(fontSize: 12, color: AppColors.greenDark)),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      color: AppColors.greenSoft,
      child: Row(
        children: [
          Icon(Icons.eco, color: AppColors.green, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.welcome,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(S.welcomeSub,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    // في RTL: الأول يظهر يميناً (الميزانية) ثم المصروف يساراً، مطابقاً للصورة.
    return const Row(
      children: [
        Expanded(
          child: _SummaryCard(
              id: 'budget',
              icon: Icons.shopping_basket_outlined,
              label: S.monthlyBudget),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
              id: 'monthly',
              icon: Icons.paid_outlined,
              label: S.monthlySpent),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.id, required this.icon, required this.label});

  final String id;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => context.push(sectionById(id).path),
      child: AppCard(
        child: Column(
          children: [
            Icon(icon, color: AppColors.green, size: 30),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('—',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const Text(S.notSet,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _BudgetUsageCard extends StatelessWidget {
  const _BudgetUsageCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.budgetUsage,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          SizedBox(height: 10),
          BudgetProgressBar(value: null),
          SizedBox(height: 8),
          Text(S.budgetEmpty,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
