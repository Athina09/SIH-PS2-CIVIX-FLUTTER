// Ported from src/components/ui/CaptchaChallenge.tsx
// A client-side-only "CAPTCHA" — there is no server to verify against, so this exists purely to
// give the sign-in flow the visual friction/reassurance of a real bot check before OTP.
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const List<Color> _inkColors = [
  CivixColors.neel,
  CivixColors.lac,
  CivixColors.sal,
  CivixColors.tasar,
  CivixColors.kusum,
];

String _randomCode([int len = 5]) {
  final rnd = Random();
  return List.generate(len, (_) => _chars[rnd.nextInt(_chars.length)]).join();
}

String _randomNoisePath(int seed) {
  final y1 = 10 + ((seed * 7) % 36);
  final y2 = 10 + ((seed * 13) % 36);
  final y3 = 10 + ((seed * 19) % 36);
  return 'M0,$y1 Q40,$y2 80,$y1 T160,$y3';
}

class CaptchaChallenge extends StatefulWidget {
  final VoidCallback onVerified;
  const CaptchaChallenge({super.key, required this.onVerified});

  @override
  State<CaptchaChallenge> createState() => _CaptchaChallengeState();
}

class _CaptchaChallengeState extends State<CaptchaChallenge> {
  late String _code = _randomCode();
  final _controller = TextEditingController();
  bool _error = false;

  void _refresh() {
    setState(() {
      _code = _randomCode();
      _controller.clear();
      _error = false;
    });
  }

  void _verify() {
    if (_controller.text.trim().toUpperCase() == _code) {
      widget.onVerified();
    } else {
      setState(() => _error = true);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final noise = [_randomNoisePath(_code.codeUnitAt(0)), _randomNoisePath(_code.codeUnitAt(1) * 3)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.verified_user_outlined, size: 15, color: CivixColors.sal),
            SizedBox(width: 6),
            Text('Security check', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 160,
              height: 56,
              decoration: BoxDecoration(
                color: CivixColors.chuna,
                border: Border.all(color: CivixColors.rule),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _CaptchaPainter(code: _code, noise: noise),
                size: const Size(160, 56),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Get a new code',
              style: IconButton.styleFrom(shape: const CircleBorder(), side: const BorderSide(color: CivixColors.rule)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _error = false),
                onSubmitted: (_) => _verify(),
                decoration: InputDecoration(
                  hintText: 'Type the code above',
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _error ? CivixColors.ember : CivixColors.rule),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _verify, child: const Text('Verify')),
          ],
        ),
        if (_error)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text("That didn't match — try the new code.", style: TextStyle(fontSize: 12, color: CivixColors.ember)),
          ),
      ],
    );
  }
}

class _CaptchaPainter extends CustomPainter {
  final String code;
  final List<String> noise;
  _CaptchaPainter({required this.code, required this.noise});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = CivixColors.rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final path in noise) {
      canvas.drawPath(_parseSvgWavePath(path), linePaint);
    }
    for (var i = 0; i < code.length; i++) {
      final ch = code[i];
      final jitter = ((ch.codeUnitAt(0) * (i + 3)) % 24) - 12;
      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _inkColors[i % _inkColors.length]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      final dx = 12.0 + i * 27;
      final dy = 14.0;
      canvas.translate(dx + tp.width / 2, dy + tp.height / 2);
      canvas.rotate(jitter * 3.14159265 / 180);
      canvas.translate(-tp.width / 2, -tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  // Approximates the source SVG's `M0,y1 Q40,y2 80,y1 T160,y3` noise path with a smooth curve.
  Path _parseSvgWavePath(String d) {
    final nums = RegExp(r'-?\d+(\.\d+)?').allMatches(d).map((m) => double.parse(m.group(0)!)).toList();
    final path = Path()..moveTo(nums[0], nums[1]);
    path.quadraticBezierTo(nums[2], nums[3], nums[4], nums[5]);
    // Reflect the previous control point for the T (smooth quadratic) command.
    final reflectedCx = nums[4] + (nums[4] - nums[2]);
    final reflectedCy = nums[5] + (nums[5] - nums[3]);
    path.quadraticBezierTo(reflectedCx, reflectedCy, nums[6], nums[7]);
    return path;
  }

  @override
  bool shouldRepaint(covariant _CaptchaPainter oldDelegate) => oldDelegate.code != code;
}
