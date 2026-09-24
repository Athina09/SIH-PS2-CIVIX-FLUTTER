// Ported from src/components/signature/Stamp.tsx
// A round lac-ink stamp marking a completed human decision. Only ever appears on documents.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

enum StampKind { validated, routed, approved, released, communityVerified }

String stampLabel(StampKind kind) {
  switch (kind) {
    case StampKind.validated:
      return 'VALIDATED';
    case StampKind.routed:
      return 'ROUTED';
    case StampKind.approved:
      return 'APPROVED';
    case StampKind.released:
      return 'RELEASED';
    case StampKind.communityVerified:
      return 'COMMUNITY-VERIFIED';
  }
}

class Stamp extends StatefulWidget {
  final StampKind kind;
  const Stamp({super.key, required this.kind});

  @override
  State<Stamp> createState() => _StampState();
}

class _StampState extends State<Stamp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        final scale = reduceMotion ? 1.0 : 1.15 - 0.15 * t;
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Semantics(
        image: true,
        label: stampLabel(widget.kind).replaceAll('-', ' ').toLowerCase(),
        child: SizedBox(
          width: 76,
          height: 76,
          child: CustomPaint(painter: _StampPainter(stampLabel(widget.kind))),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  final String label;
  _StampPainter(this.label);

  static const double size = 76;
  static const double rOuter = 34;
  static const double rInner = 27;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = size / 2;
    final cy = size / 2;
    final ink = CivixColors.lac;

    final outerPaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final innerPaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dotPaint = Paint()..color = ink;

    canvas.drawCircle(Offset(cx, cy), rOuter, outerPaint);
    canvas.drawCircle(Offset(cx, cy), rInner, innerPaint);
    canvas.drawCircle(Offset(cx, cy), 3, dotPaint);

    // Draw the label letters along the top arc of the inner circle.
    final radius = rInner - 10;
    final chars = label.split('');
    const letterSpacingRad = 0.19;
    final totalAngle = (chars.length - 1) * letterSpacingRad;
    final startAngle = -math.pi / 2 - totalAngle / 2;

    for (var i = 0; i < chars.length; i++) {
      final angle = startAngle + i * letterSpacingRad;
      final tp = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: const TextStyle(color: CivixColors.lac, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StampPainter oldDelegate) => oldDelegate.label != label;
}
