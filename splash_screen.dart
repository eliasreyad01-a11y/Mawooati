import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/motion/app_motion.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/shared/widgets/mawoonati_logo.dart';

/// شاشة البداية (~2.4 ث). مرة واحدة بلا تكرار، ثم تنتقل للرئيسية.
/// (في المرحلة 2 ستنتقل لتسجيل الدخول إن لم يكن هناك حساب.)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _reduce = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = shouldReduceMotion(context, ref);
    _c.duration = _reduce ? AppMotion.splashReduced : AppMotion.splash;
    _c.forward().whenComplete(() async {
      if (_reduce) await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _t(double begin, double end) =>
      _reduce ? 1 : Interval(begin, end, curve: AppMotion.standard).transform(_c.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenSoft,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final nameT = _t(0.42, 0.63);
          final tagT = _t(0.58, 0.79);
          return Opacity(
            opacity: _reduce ? _c.value : 1,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LogoMark(
                    size: 180,
                    roof: _t(0.0, 0.35),
                    cart: _t(0.17, 0.42),
                    leaves: _t(0.25, 0.5),
                  ),
                  Opacity(
                    opacity: nameT,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - nameT)),
                      child: const Column(children: [
                        Text(S.appName,
                            style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenDark,
                                height: 1.2)),
                        Text(S.appNameEn,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greenDark)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: tagT,
                    child: const Text(S.tagline,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
