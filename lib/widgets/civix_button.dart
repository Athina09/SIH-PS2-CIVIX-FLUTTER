// Ported from src/components/ui/Button.tsx
import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum CivixButtonVariant { primary, secondary, ghost, danger, outline }

enum CivixButtonSize { sm, md, lg }

class CivixButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CivixButtonVariant variant;
  final CivixButtonSize size;
  final IconData? icon;

  const CivixButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CivixButtonVariant.primary,
    this.size = CivixButtonSize.md,
    this.icon,
  });

  double get _minHeight {
    switch (size) {
      case CivixButtonSize.sm:
        return 36;
      case CivixButtonSize.md:
        return 44;
      case CivixButtonSize.lg:
        return 52;
    }
  }

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case CivixButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CivixButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case CivixButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  double get _fontSize {
    switch (size) {
      case CivixButtonSize.sm:
        return 12;
      case CivixButtonSize.md:
        return 14;
      case CivixButtonSize.lg:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Theme.of(context).colorScheme.primary;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: _fontSize + 2), const SizedBox(width: 8)],
        Text(label, style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500)),
      ],
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

    switch (variant) {
      case CivixButtonVariant.primary:
        return SizedBox(
          height: _minHeight,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(backgroundColor: role, foregroundColor: Colors.white, padding: _padding, shape: shape, elevation: 0),
            child: content,
          ),
        );
      case CivixButtonVariant.danger:
        return SizedBox(
          height: _minHeight,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(backgroundColor: CivixColors.ember, foregroundColor: Colors.white, padding: _padding, shape: shape, elevation: 0),
            child: content,
          ),
        );
      case CivixButtonVariant.secondary:
        return SizedBox(
          height: _minHeight,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: CivixColors.neel,
              side: const BorderSide(color: CivixColors.rule),
              padding: _padding,
              shape: shape,
            ),
            child: content,
          ),
        );
      case CivixButtonVariant.outline:
        return SizedBox(
          height: _minHeight,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: role,
              side: BorderSide(color: role, width: 2),
              padding: _padding,
              shape: shape,
            ),
            child: content,
          ),
        );
      case CivixButtonVariant.ghost:
        return SizedBox(
          height: _minHeight,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(foregroundColor: CivixColors.neel, padding: _padding, shape: shape),
            child: content,
          ),
        );
    }
  }
}
