import 'package:flutter/material.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/sections.dart';
import 'package:mawoonati/features/common/empty_state.dart';

/// شاشة صريحة للأقسام غير المنفَّذة بعد؛ لا تدّعي أن الميزة تعمل.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.section});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: EmptyState(
        icon: section.icon,
        title: section.title,
        body: '${S.comingIn} المرحلة ${section.phase}: ${phaseNames[section.phase]}.',
      ),
    );
  }
}
