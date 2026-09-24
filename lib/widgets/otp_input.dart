// Ported from src/components/ui/OtpInput.tsx
// A simulated OTP step — no SMS gateway exists in this demo, so instead of exposing the "sent"
// code on screen, it autofills a moment later the way a phone's real SMS autofill would, keeping
// the flow visually real and unblocked without ever showing the code in plain text.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class OtpInput extends StatefulWidget {
  final String destination;
  final VoidCallback onVerified;
  const OtpInput({super.key, required this.destination, required this.onVerified});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final String _sentCode = (100000 + Random().nextInt(900000)).toString();
  final List<String> _digits = List.filled(6, '');
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _error = false;
  int _seconds = 30;
  bool _autofilled = false;
  Timer? _countdown;
  Timer? _autofillTimer;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
    });
    _autofillTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < 6; i++) {
          _digits[i] = _sentCode[i];
          _controllers[i].text = _sentCode[i];
        }
        _autofilled = true;
      });
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _autofillTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _setDigit(int i, String val) {
    final v = val.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _digits[i] = v.isNotEmpty ? v.substring(v.length - 1) : '';
      _error = false;
    });
    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
  }

  void _verify() {
    if (_digits.join() == _sentCode) {
      widget.onVerified();
    } else {
      setState(() => _error = true);
    }
  }

  void _resend() {
    setState(() => _seconds = 30);
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.sms_outlined, size: 15, color: CivixColors.sal),
            SizedBox(width: 6),
            Text('Verify with OTP', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
            children: [
              TextSpan(
                  text:
                      'A 6-digit code was sent to ${widget.destination.isNotEmpty ? widget.destination : 'your registered mobile number'}. '),
              TextSpan(
                text: _autofilled ? 'Autofilled from SMS.' : 'Waiting to autofill…',
                style: TextStyle(color: _autofilled ? CivixColors.sal : CivixColors.neelSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 42,
              height: 48,
              child: TextField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _error ? CivixColors.ember : CivixColors.rule),
                  ),
                ),
                onChanged: (v) => _setDigit(i, v),
              ),
            );
          }),
        ),
        if (_error)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Incorrect code — check the digits above and try again.',
                style: TextStyle(fontSize: 12, color: CivixColors.ember)),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _seconds > 0 ? null : _resend,
              child: Text(_seconds > 0 ? 'Resend OTP in ${_seconds}s' : 'Resend OTP'),
            ),
            FilledButton(onPressed: _verify, child: const Text('Verify & continue')),
          ],
        ),
      ],
    );
  }
}
