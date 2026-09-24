// Ported from src/components/ui/StatusChip.tsx
import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum ChipTone { neutral, progress, success, risk, failed }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  const StatusChip({super.key, required this.label, this.tone = ChipTone.neutral});

  Color get _color {
    switch (tone) {
      case ChipTone.neutral:
        return CivixColors.neel;
      case ChipTone.progress:
        return CivixColors.neel;
      case ChipTone.success:
        return CivixColors.lac;
      case ChipTone.risk:
        return CivixColors.ember;
      case ChipTone.failed:
        return CivixColors.ember;
    }
  }

  IconData get _icon {
    switch (tone) {
      case ChipTone.neutral:
        return Icons.circle_outlined;
      case ChipTone.progress:
        return Icons.schedule;
      case ChipTone.success:
        return Icons.check_circle;
      case ChipTone.risk:
        return Icons.warning_amber;
      case ChipTone.failed:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border(
          top: const BorderSide(color: CivixColors.rule),
          right: const BorderSide(color: CivixColors.rule),
          bottom: const BorderSide(color: CivixColors.rule),
          left: BorderSide(color: _color, width: 4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: _color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _color)),
        ],
      ),
    );
  }
}
