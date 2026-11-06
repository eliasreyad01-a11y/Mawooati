import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:mawoonati/core/utils/validators.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/features/auth/auth_scaffold.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _needsConfirm = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final needs = await ref
          .read(authRepositoryProvider)
          .signUp(_email.text, _password.text, _name.text);
      if (mounted && needs) setState(() => _needsConfirm = true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsConfirm) {
      return AuthScaffold(
        title: 'تحقق من بريدك',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormMessage(
              isError: false,
              text: 'أرسلنا رابط التأكيد إلى ${_email.text.trim()}. افتحه ثم سجّل الدخول.',
            ),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('العودة لتسجيل الدخول'),
            ),
          ],
        ),
      );
    }
    return AuthScaffold(
      title: 'إنشاء حساب جديد',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) FormMessage(text: _error!),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: fieldDecoration('الاسم', icon: Icons.person_outline),
              validator: (v) => Validators.required(v, 'أدخل اسمك', max: 60),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: fieldDecoration('البريد الإلكتروني', icon: Icons.mail_outline),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: fieldDecoration('كلمة المرور', icon: Icons.lock_outline),
              validator: Validators.password,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              textDirection: TextDirection.ltr,
              onFieldSubmitted: (_) => _submit(),
              decoration: fieldDecoration('تأكيد كلمة المرور', icon: Icons.lock_outline),
              validator: (v) => Validators.confirmPassword(v, _password.text),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إنشاء الحساب'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('لديك حساب؟ سجّل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}
