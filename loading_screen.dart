import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/session/session_gate.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/features/common/empty_state.dart';

/// تظهر أثناء تحميل بيانات المنزل بعد الدخول، أو عند فشل التحميل مع إعادة المحاولة.
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  late final SessionGate _gate = ref.read(sessionGateProvider);

  @override
  void initState() {
    super.initState();
    _gate.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _gate.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_gate.loadFailed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: Icons.wifi_off,
            title: 'تعذّر التحميل',
            body: 'تحقق من الإنترنت ثم أعد المحاولة.',
          ),
          FilledButton(onPressed: _gate.refresh, child: const Text('إعادة المحاولة')),
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
