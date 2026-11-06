import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:mawoonati/core/utils/validators.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/features/auth/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // عند النجاح يتولى SessionGate التوجيه تلقائياً.
      await ref.read(authRepositoryProvider).signIn(_email.text, _password.text);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'تسجيل الدخول',
      subtitle: 'أهلاً بعودتك إلى مؤونتي',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) FormMessage(text: _error!),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: fieldDecoration('البريد الإلكتروني', icon: Icons.mail_outline),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _hide,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: fieldDecoration('كلمة المرور', icon: Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  tooltip: _hide ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'أدخل كلمة المرور' : null,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('نسيت كلمة المرور؟'),
              ),
            ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('دخول'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/signup'),
              child: const Text('ليس لديك حساب؟ أنشئ حساباً'),
            ),
          ],
        ),
      ),
    );
  }
}
