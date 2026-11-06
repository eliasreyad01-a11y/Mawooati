import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/motion/app_motion.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';

/// ظهور Fade + Slide مرة واحدة. [index] يُحدد التأخير المتدرج (حتى 6 عناصر).
/// عند تقليل الحركة يظهر العنصر فوراً.
class AnimatedEntrance extends ConsumerStatefulWidget {
  const AnimatedEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  ConsumerState<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends ConsumerState<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.entrance);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (shouldReduceMotion(context, ref)) {
      _c.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 50 * widget.index.clamp(0, 6));
    _timer = Timer(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.standard);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(curved),
        child: widget.child,
      ),
    );
  }
}
