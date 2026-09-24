// Ported from src/components/ui/Panel.tsx
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CivixColors.page,
        border: Border.all(color: CivixColors.rule),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class Block extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Block({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CivixColors.rule),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
