// Ported from src/components/ui/AIBadge.tsx
// A small "AI is doing work here" marker — used anywhere the pipeline is scoring, matching,
// de-duplicating or drafting something automatically, so that work stays visible to the user.
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AIBadge extends StatelessWidget {
  final String label;
  const AIBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: CivixColors.kusum.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CivixColors.kusum.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 11, color: CivixColors.kusum),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.kusum)),
        ],
      ),
    );
  }
}
