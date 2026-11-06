import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:mawoonati/core/l10n/strings.dart';
import 'package:mawoonati/core/theme/app_colors.dart';

/// شعار مؤونتي (منزل + عربة + أوراق). الإحداثيات مطابقة لـ assets/logo/mawoonati_mark.svg.
/// المعاملات [roof] و[cart] و[leaves] (0..1) تُستخدم لأنيميشن شاشة البداية.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 120,
    this.roof = 1,
    this.cart = 1,
    this.leaves = 1,
  });

  final double size;
  final double roof;
  final double cart;
  final double leaves;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.logoLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LogoPainter(roof, cart, leaves)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.roof, this.cart, this.leaves);
  final double roof, cart, leaves;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _partial(Canvas canvas, Path p, Paint paint, double t) {
    for (final PathMetric m in p.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);

    // السقف + المدخنة
    final roofPath = Path()
      ..moveTo(28, 104)
      ..lineTo(100, 38)
      ..lineTo(172, 104);
    final chimney = Path()
      ..moveTo(138, 68)
      ..lineTo(138, 46)
      ..lineTo(152, 46)
      ..lineTo(152, 80);
    final roofPaint = _stroke(AppColors.greenDark, 11);
    if (roof > 0) {
      _partial(canvas, roofPath, roofPaint, roof);
      _partial(canvas, chimney, roofPaint, roof);
    }

    // العربة (تنزلق من اليمين وتظهر تدريجياً)
    if (cart > 0) {
      canvas.save();
      canvas.translate(24 * (1 - cart), 0);
      final dark = AppColors.greenDark.withValues(alpha: cart);
      final body = Path()
        ..moveTo(84, 76)
        ..lineTo(94, 76)
        ..lineTo(103, 118)
        ..lineTo(140, 118)
        ..lineTo(150, 88)
        ..lineTo(97, 88);
      canvas.drawPath(body, _stroke(dark, 7));
      final grid = Path()
        ..moveTo(104, 103)
        ..lineTo(146, 103)
        ..moveTo(118, 88)
        ..lineTo(118, 118)
        ..moveTo(132, 88)
        ..lineTo(132, 118);
      canvas.drawPath(grid, _stroke(dark, 4));
      final fill = Paint()..color = dark;
      canvas.drawCircle(const Offset(108, 130), 5.5, fill);
      canvas.drawCircle(const Offset(134, 130), 5.5, fill);
      canvas.restore();
    }

    // الأوراق (تتفتح من قاعدتها)
    if (leaves > 0) {
      canvas.save();
      canvas.translate(50, 140);
      canvas.scale(0.6 + 0.4 * leaves);
      canvas.translate(-50, -140);
      final big = Path()
        ..moveTo(66, 124)
        ..cubicTo(40, 112, 34, 82, 58, 58)
        ..cubicTo(80, 76, 84, 106, 66, 124)
        ..close();
      final small = Path()
        ..moveTo(50, 144)
        ..cubicTo(30, 142, 20, 124, 28, 108)
        ..cubicTo(46, 110, 58, 124, 50, 144)
        ..close();
      canvas.drawPath(
          big, Paint()..color = AppColors.green.withValues(alpha: leaves));
      canvas.drawPath(
          small, Paint()..color = AppColors.greenLeaf.withValues(alpha: leaves));
      canvas.restore();
    }

    // القوس السفلي
    final swoosh = Path()
      ..moveTo(22, 158)
      ..quadraticBezierTo(100, 134, 178, 158);
    if (roof > 0) {
      _partial(canvas, swoosh, _stroke(AppColors.green, 5), roof);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter o) =>
      o.roof != roof || o.cart != cart || o.leaves != leaves;
}
