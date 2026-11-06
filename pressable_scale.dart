import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/motion/app_motion.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';

/// حركة ضغط خفيفة (تصغير 4%) تُعطَّل عند تقليل الحركة.
class PressableScale extends ConsumerStatefulWidget {
  const PressableScale({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  ConsumerState<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends ConsumerState<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = shouldReduceMotion(context, ref);
    return Semantics(
      button: true,
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (_down && !reduce) ? 0.96 : 1.0,
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}
