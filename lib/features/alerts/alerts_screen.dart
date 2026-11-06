import 'package:flutter/material.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/features/common/empty_state.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.navAlerts)),
      body: const EmptyState(
        icon: Icons.notifications_none,
        title: S.alertsEmptyTitle,
        body: S.alertsEmptyBody,
      ),
    );
  }
}
