// Ported from src/components/ui/MergedBadge.tsx
// Highlights that a master issue is the result of a duplicate merge, and how many citizen
// reports now feed it — shown wherever that issue appears so the merge is visible everywhere.
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class MergedBadge extends StatelessWidget {
  final int count;
  const MergedBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Tooltip(
      message: '$count reports merged into this case',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: CivixColors.ember.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 12, color: CivixColors.ember),
            const SizedBox(width: 4),
            Text('$count reports merged', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CivixColors.ember)),
          ],
        ),
      ),
    );
  }
}
