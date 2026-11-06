import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:mawoonati/core/session/session_gate.dart';
import 'package:mawoonati/core/utils/validators.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/features/auth/auth_scaffold.dart';
import 'package:mawoonati/features/household/household_repository.dart';

const supportedCurrencies = {
  'JOD': 'دينار أردني (د.أ)',
  'USD': 'دولار أمريكي (\$)',
  'EUR': 'يورو (€)',
  'SAR': 'ريال سعودي (ر.س)',
  'AED': 'درهم إماراتي (د.إ)',
};

class SetupHouseholdScreen extends ConsumerStatefulWidget {
  const SetupHouseholdScreen({super.key});

  @override
  ConsumerState<SetupHouseholdScreen> createState() => _SetupHouseholdScreenState();
}

class _SetupHouseholdScreenState extends ConsumerState<SetupHouseholdScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _currency = 'JOD';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(householdRepositoryProvider)
          .createHousehold(name: _name.text, currency: _currency);
      await ref.read(sessionGateProvider).refresh(); // يوجّه للرئيسية
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'إعداد منزلك',
      subtitle: 'سيُنشأ لك منزل بأماكن تخزين وتصنيفات افتراضية يمكنك تعديلها لاحقاً.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) FormMessage(text: _error!),
            TextFormField(
              controller: _name,
              decoration: fieldDecoration('اسم المنزل', icon: Icons.home_outlined),
              validator: (v) => Validators.required(v, 'أدخل اسم المنزل'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: fieldDecoration('العملة', icon: Icons.payments_outlined),
              items: [
                for (final e in supportedCurrencies.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _currency = v ?? 'JOD'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إنشاء المنزل'),
            ),
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}
