import 'package:flutter/material.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/features/common/empty_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.navInventory)),
      body: const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: S.inventoryEmptyTitle,
        body: S.inventoryEmptyBody,
      ),
    );
  }
}
